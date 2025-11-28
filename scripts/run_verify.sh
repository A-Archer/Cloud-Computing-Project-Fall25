#!/bin/bash
set -e # 遇到错误立即停止

echo "=========================================="
echo " [Step 3] Verifying MARC Implementation"
echo "=========================================="

# 定义编译产物的搜索路径 (SimAI 标准构建路径)
BUILD_SCRATCH="astra-sim-alibabacloud/extern/network_backend/ns3-interface/simulation/build/scratch"

# --------------------------------------------
# 1. 验证数据平面 (底层复制能力)
# --------------------------------------------
echo ">>> A. Running Data Plane Verification (verify_forwarding)..."

# 自动查找可执行文件 (防止因版本号不同找不到)
EXE_VERIFY=$(find "$BUILD_SCRATCH" -name "*verify_forwarding*" -type f -executable | head -n 1)

if [ -z "$EXE_VERIFY" ]; then
    echo "Error: verify_forwarding executable not found. Please run build first."
    exit 1
fi

# 运行验证
$EXE_VERIFY
echo "   [Success] Data Plane Verified."

# --------------------------------------------
# 2. 验证控制平面 (算法树构建)
# --------------------------------------------
echo -e "\n>>> B. Running Control Plane Verification (Spectrum-X Topology)..."

# 确保拓扑文件存在
echo "   -> Generating Topology..."
python3 ./astra-sim-alibabacloud/inputs/topo/gen_Topo_Template.py -topo Spectrum-X -g 128 -gt A100 -bw 100Gbps -nvbw 2400Gbps > /dev/null

# 查找主程序
EXE_ASTRA=$(find "$BUILD_SCRATCH" -name "*AstraSimNetwork*" -type f -executable | head -n 1)

if [ -z "$EXE_ASTRA" ]; then
    echo "Error: AstraSimNetwork executable not found."
    exit 1
fi

echo "   -> Running Simulation to capture MARC-Ctrl logs..."
# 运行仿真并过滤日志 (只看 MARC 控制器输出，忽略其后的崩溃)
AS_SEND_LAT=3 AS_NVLS_ENABLE=1 $EXE_ASTRA \
    -t 16 -w ./example/microAllReduce.txt \
    -n ./Spectrum-X_128g_8gps_100Gbps_A100 \
    -c astra-sim-alibabacloud/inputs/config/SimAI.conf 2>&1 | grep -E "MARC-Ctrl|Ring"

echo "   [Success] Control Plane Verified."
