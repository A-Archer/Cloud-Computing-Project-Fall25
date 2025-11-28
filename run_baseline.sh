#!/bin/bash
# run_baseline.sh - 采集 Ring 算法基准数据

# 定义消息大小 (2MB 到 512MB)
SIZES=(2097152 4194304 8388608 16777216 33554432 67108864 134217728 268435456 536870912)
LABELS=("2MB" "4MB" "8MB" "16MB" "32MB" "64MB" "128MB" "256MB" "512MB")

# 输出文件
OUTPUT_CSV="ring_results.csv"
echo "Size_MB,CCT_ns" > $OUTPUT_CSV

# 备份您的好文件！
cp ./example/microAllReduce.txt ./example/microAllReduce.txt.bak

echo "========================================"
echo "Starting Baseline Sweep (Ring Algorithm)"
echo "========================================"

for i in "${!SIZES[@]}"; do
    SIZE_BYTES=${SIZES[$i]}
    SIZE_LABEL=${LABELS[$i]}
    
    echo "[Run] Testing Message Size: $SIZE_LABEL ($SIZE_BYTES bytes)..."
    
    # --- 1. 精确修改第 5 列 (Message Size) ---
    # 逻辑：找到包含 'ALLREDUCE' 的行，将第 5 列替换为当前大小
    awk -v sz="$SIZE_BYTES" '/ALLREDUCE/ {$5=sz} 1' ./example/microAllReduce.txt.bak > ./example/microAllReduce.txt
    
    # --- 2. 运行仿真 ---
    # 使用 grep 抓取最后一行包含 "total time" 的数据
    # 输出会被重定向到临时文件以便提取
    AS_SEND_LAT=3 AS_NVLS_ENABLE=1 ./bin/SimAI_simulator \
        -t 16 \
        -w ./example/microAllReduce.txt \
        -n ./Spectrum-X_128g_8gps_100Gbps_A100 \
        -c astra-sim-alibabacloud/inputs/config/SimAI.conf > current_run.log 2>&1
    
    # --- 3. 提取 CCT ---
    # 查找 ncclFlowModel_EndToEnd.csv 或直接从日志分析
    # 根据您之前提供的信息，结果在 ncclFlowModel_EndToEnd.csv 的最后一行，格式为 ...,total time,1688.030000
    if [ -f "ncclFlowModel_EndToEnd.csv" ]; then
        # 提取 "total time," 后面的数字
        CCT=$(grep "total time" ncclFlowModel_EndToEnd.csv | tail -n 1 | awk -F'total time,' '{print $2}')
    else
        CCT="0"
    fi
    
    # 清理换行符
    CCT=$(echo $CCT | tr -d '\r\n')
    
    echo "   -> Time: $CCT"
    echo "$SIZE_LABEL,$CCT" >> $OUTPUT_CSV
done

# 恢复原始文件
mv ./example/microAllReduce.txt.bak ./example/microAllReduce.txt
echo "Done! Results saved to $OUTPUT_CSV"
