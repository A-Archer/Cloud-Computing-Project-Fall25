#!/bin/bash
set -e
echo "=========================================="
echo " [Step 4] Running Performance Benchmarks"
echo "=========================================="

BUILD_SCRATCH="astra-sim-alibabacloud/extern/network_backend/ns3-interface/simulation/build/scratch"

# --------------------------------------------
# 1. 生成 MARC 实测数据 (marc_results.csv)
# --------------------------------------------
echo ">>> A. Generating Real Measurement Data (marc_perf_test)..."
EXE_PERF=$(find "$BUILD_SCRATCH" -name "*marc_perf_test*" -type f -executable | head -n 1)

if [ -z "$EXE_PERF" ]; then
    echo "Error: marc_perf_test executable not found."
    exit 1
fi

# 运行并保存
$EXE_PERF > marc_results.csv
echo "   -> Data saved to marc_results.csv"

# --------------------------------------------
# 2. 生成 Ring 基准数据 (ring_results.csv)
# --------------------------------------------
echo ">>> B. Generating Baseline Data (SimAI Sweep)..."
EXE_ASTRA=$(find "$BUILD_SCRATCH" -name "*AstraSimNetwork*" -type f -executable | head -n 1)

# 初始化 CSV 和备份 Workload
echo "Size_MB,CCT_ns" > ring_results.csv
cp ./example/microAllReduce.txt ./example/microAllReduce.bak

# 定义测试参数
SIZES=(2097152 4194304 8388608 16777216 33554432 67108864 134217728 268435456 536870912)
LABELS=("2MB" "4MB" "8MB" "16MB" "32MB" "64MB" "128MB" "256MB" "512MB")

for i in "${!SIZES[@]}"; do
    SIZE=${SIZES[$i]}
    LABEL=${LABELS[$i]}
    echo "   -> Running Ring for $LABEL ($SIZE bytes)..."
    
    # 修改 workload (第5列)
    awk -v sz="$SIZE" '/ALLREDUCE/ {$5=sz} 1' ./example/microAllReduce.bak > ./example/microAllReduce.txt
    
    # 运行仿真 (屏蔽大量日志，只看结果)
    AS_SEND_LAT=3 AS_NVLS_ENABLE=1 $EXE_ASTRA \
        -t 16 -w ./example/microAllReduce.txt \
        -n ./Spectrum-X_128g_8gps_100Gbps_A100 \
        -c astra-sim-alibabacloud/inputs/config/SimAI.conf > run_temp.log 2>&1
    
    # 提取时间 (从 CSV 中提取 total time)
    if [ -f "ncclFlowModel_EndToEnd.csv" ]; then
        # 提取 'total time' 后的数值
        CCT=$(grep "total time" ncclFlowModel_EndToEnd.csv | tail -n 1 | awk -F'total time,' '{print $2}' | tr -d '\r\n,')
    else
        CCT="0"
    fi
    
    # 如果提取为空，设为 0
    if [ -z "$CCT" ]; then CCT="0"; fi
    
    echo "$LABEL,$CCT" >> ring_results.csv
done

# 恢复原始 Workload 文件
mv ./example/microAllReduce.bak ./example/microAllReduce.txt
echo "   -> Data saved to ring_results.csv"
