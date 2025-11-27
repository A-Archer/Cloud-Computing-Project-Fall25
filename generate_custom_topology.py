import json
import random
import math
import os

# ================= 配置参数 =================
# 1. 拓扑参数 (8-ary Fat-Tree)
K_ARY = 8
PODS = K_ARY
TORS_PER_POD = K_ARY // 2  # 4 ToRs per Pod
SERVERS_PER_TOR = K_ARY // 2  # 4 Servers per ToR
GPUS_PER_SERVER = 8

# 计算总规模
NUM_SERVERS = PODS * TORS_PER_POD * SERVERS_PER_TOR  # 8 * 4 * 4 = 128 Servers
TOTAL_GPUS = NUM_SERVERS * GPUS_PER_SERVER           # 1024 GPUs

# 2. 带宽与延迟配置 (注意 SimAI 单位通常为 Gbps)
BW_NVLINK = 900.0 * 8   # 900 GB/s = 7200 Gbps
BW_ETH = 100.0          # 100 Gbps
LAT_NVLINK = 500        # ns (估算值)
LAT_ETH = 5000          # ns (估算值)

# 3. 流量参数 (Poisson Broadcast)
LAMBDA = 100            # 到达率 (jobs/sec)
SIM_TIME = 0.1          # 模拟时长 (秒)
MIN_MSG_SIZE = 1 * 1024 * 1024      # 1MB
MAX_MSG_SIZE = 128 * 1024 * 1024    # 128MB

# ================= 1. 生成 System Configuration (NVLink) =================
# system.json 定义了 GPU 的基本属性和 NVLink 带宽
def generate_system_config():
    sys_config = {
        "scheduling-policy": "LIFO",
        "endpoint-delay": 10,
        "active-chunks-per-dimension": 1,
        "preferred-dataset-splits": 4,
        "all-reduce-implementation": ["direct", "direct"], # Dim0: NVLink, Dim1: Network
        "all-gather-implementation": ["direct", "direct"],
        "reduce-scatter-implementation": ["direct", "direct"],
        "all-to-all-implementation": ["direct", "direct"],
        "collective-optimization": "baseline",
        "intra-dimension-scheduling": "FIFO",
        "inter-dimension-scheduling": "FIFO",
        "dimensions-count": 2,
        # [Dim0 Bandwidth, Dim1 Bandwidth]
        # 注意：对于 Analytical 模型，这里设置默认带宽；复杂拓扑会在 network 文件中指定
        "bandwidth": [BW_NVLINK, BW_ETH] 
    }
    
    with open("custom_system.json", "w") as f:
        json.dump(sys_config, f, indent=4)
    print(f"[OK] Generated custom_system.json (NVLink: {BW_NVLINK} Gbps)")

# ================= 2. 生成 Network Topology (8-ary Fat-Tree) =================
# 这里的重点是生成 Server 之间的连接关系 (Dimension 1)
# SimAI Analytical Backend 通常接受一个简单的边列表或特定的格式
# 这里我们生成通用的 Astra-Sim Network 格式 (id source destination bandwidth latency)
def generate_fattree_topology():
    links = []
    
    # --- 节点编号规划 ---
    # Servers: 0 ~ 127
    # ToR Switches: 128 ~ 159 (8 pods * 4 ToRs)
    # Agg Switches: 160 ~ 191 (8 pods * 4 Aggs)
    # Core Switches: 192 ~ 207 ( (k/2)^2 = 16 Cores)
    
    SERVER_OFFSET = 0
    TOR_OFFSET = NUM_SERVERS
    AGG_OFFSET = TOR_OFFSET + (PODS * TORS_PER_POD)
    CORE_OFFSET = AGG_OFFSET + (PODS * (K_ARY // 2))
    
    # 辅助函数：添加双向链路
    def add_bi_link(u, v, bw, lat):
        # 格式: src dst bw lat
        links.append(f"{u} {v} {bw} {lat}")
        links.append(f"{v} {u} {bw} {lat}")

    # A. 连接 Server <-> ToR
    for pod in range(PODS):
        for tor in range(TORS_PER_POD):
            tor_id = TOR_OFFSET + pod * TORS_PER_POD + tor
            for s in range(SERVERS_PER_TOR):
                # 计算 Server ID
                # 逻辑上：Pod 0 -> ToR 0 -> [Server 0-3]
                global_server_id = (pod * TORS_PER_POD * SERVERS_PER_TOR) + \
                                   (tor * SERVERS_PER_TOR) + s
                add_bi_link(global_server_id, tor_id, BW_ETH, LAT_ETH)

    # B. 连接 ToR <-> Agg (Pod 内部 Full Mesh)
    for pod in range(PODS):
        for tor in range(TORS_PER_POD):
            tor_id = TOR_OFFSET + pod * TORS_PER_POD + tor
            for agg in range(K_ARY // 2):
                agg_id = AGG_OFFSET + pod * (K_ARY // 2) + agg
                add_bi_link(tor_id, agg_id, BW_ETH, LAT_ETH)

    # C. 连接 Agg <-> Core (Stride 连接)
    # Fat-Tree 规则: Agg switch j in Pod i connects to Core switches [(j * k/2) + stride]
    # Core switches organized as (k/2) groups of (k/2) switches
    for pod in range(PODS):
        for agg in range(K_ARY // 2): # agg index within pod (0-3)
            agg_id = AGG_OFFSET + pod * (K_ARY // 2) + agg
            
            # 每个 Agg 连接到 k/2 个 Core
            # Agg j 连接到 Core group j
            for c in range(K_ARY // 2):
                core_index = agg * (K_ARY // 2) + c
                core_id = CORE_OFFSET + core_index
                add_bi_link(agg_id, core_id, BW_ETH, LAT_ETH)

    # 写入文件 (第一行通常是节点数或格式说明，视解析器而定，这里输出纯边列表)
    with open("custom_network.txt", "w") as f:
        for link in links:
            f.write(link + "\n")
    print(f"[OK] Generated custom_network.txt (8-ary Fat-Tree, {len(links)//2} bi-links)")

# ================= 3. 生成 Workload Trace (Poisson Broadcast) =================
def generate_workload():
    jobs = []
    current_time = 0.0
    
    # Poisson Process: Inter-arrival time ~ Exponential(1/lambda)
    while current_time < SIM_TIME:
        inter_arrival = random.expovariate(LAMBDA)
        current_time += inter_arrival
        if current_time > SIM_TIME: break
        
        # 随机消息大小
        msg_size = random.randint(MIN_MSG_SIZE, MAX_MSG_SIZE)
        
        # Scale (GPU Count) - 这里简单设定几种规格
        scale = random.choice([8, 16, 32, 64, 128])
        
        # Job Locality (关键): 
        # 优先填满同一个 Server (8 GPUs), 然后是同一个 ToR, 然后是同一个 Pod
        # 我们随机选一个起始 Server，然后连续选取 GPU ID
        start_server = random.randint(0, NUM_SERVERS - (scale // 8))
        start_gpu_id = start_server * 8
        
        # 简单的 ID 列表 (因为我们假设 0-7 是 Server0, 8-15 是 Server1...)
        # Astra-Sim Trace 格式: 
        # ID  Time  Type  Size  Communicators...
        # 这里的 Communicators 指的是参与通信的 GPU ID 列表
        gpu_ids = [str(i) for i in range(start_gpu_id, start_gpu_id + scale)]
        
        # BROADCAST 通常需要指定 Root，这里假设第一个 GPU 是 Root
        job_line = f"{len(jobs)} {current_time:.9f} BROADCAST {msg_size} {' '.join(gpu_ids)}"
        jobs.append(job_line)

    with open("custom_workload.txt", "w") as f:
        for job in jobs:
            f.write(job + "\n")
            
    print(f"[OK] Generated custom_workload.txt ({len(jobs)} Broadcast jobs)")

if __name__ == "__main__":
    generate_system_config()
    generate_fattree_topology()
    generate_workload()
    print("\n所有文件生成完毕。请按照下一步指示运行 SimAI。")
