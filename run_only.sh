#!/bin/bash
# run_only.sh - 使用现有脚本运行实验

# ==========================================
# 1. 生成数据 A (NS-3 实测: marc_results.csv)
# ==========================================
echo ">>> [1/3] Generating Real Measurement Data..."
cd astra-sim-alibabacloud/extern/network_backend/ns3-interface/simulation/build

# 确保 C++ 测试程序已编译
make scratch_marc_perf_test -j4

# 运行并保存数据
EXE=$(find ./scratch -name "*marc_perf_test*" -type f -executable | head -n 1)
$EXE > ../../../../../../marc_results.csv

# 回到根目录绘图
cd ../../../../../../
if [ -f "plot_real.py" ]; then
    python3 plot_real.py
else
    echo "Error: plot_real.py 不存在，请确认您已创建该文件！"
fi

# ==========================================
# 2. 生成数据 B (SimAI Ring 基准: ring_results.csv)
# ==========================================
echo ">>> [2/3] Generating Baseline Data (SimAI Sweep)..."

# 备份 workload
cp ./example/microAllReduce.txt ./example/microAllReduce.txt.orig

# 定义参数
SIZES=(2097152 4194304 8388608 16777216 33554432 67108864 134217728 268435456 536870912)
LABELS=("2MB" "4MB" "8MB" "16MB" "32MB" "64MB" "128MB" "256MB" "512MB")
echo "Size_MB,CCT_ns" > ring_results.csv

# 循环运行仿真
for i in "${!SIZES[@]}"; do
    SIZE=${SIZES[$i]}
    LABEL=${LABELS[$i]}
    echo "Running Ring for $LABEL..."
    
    # 修改 workload (第5列)
    awk -v sz="$SIZE" '/ALLREDUCE/ {$5=sz} 1' ./example/microAllReduce.txt.orig > ./example/microAllReduce.txt
    
    # 运行仿真
    AS_SEND_LAT=3 AS_NVLS_ENABLE=1 ./bin/SimAI_simulator \
        -t 16 -w ./example/microAllReduce.txt \
        -n ./Spectrum-X_128g_8gps_100Gbps_A100 \
        -c astra-sim-alibabacloud/inputs/config/SimAI.conf > run_temp.log 2>&1
        
    # 提取数据
    if [ -f "ncclFlowModel_EndToEnd.csv" ]; then
        CCT=$(grep "total time" ncclFlowModel_EndToEnd.csv | tail -n 1 | awk -F'total time,' '{print $2}' | tr -d '\r\n')
    else
        CCT="0"
    fi
    
    if [ -z "$CCT" ]; then CCT="0"; fi
    echo "$LABEL,$CCT" >> ring_results.csv
done

# 恢复文件
mv ./example/microAllReduce.txt.orig ./example/microAllReduce.txt

# ==========================================
# 3. 生成最终对比图
# ==========================================
echo ">>> [3/3] Plotting Final Comparison..."
if [ -f "plot_projected.py" ]; then
    python3 plot_projected.py
else
    echo "Error: plot_projected.py 不存在，请确认您已创建该文件！"
fi

echo "=========================================="
echo "Done! Check 'Figure_A_Real_Measurement.png' and 'Figure_B_Full_System_Projection.png'"
echo "=========================================="
