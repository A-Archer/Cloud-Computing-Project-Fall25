#!/bin/bash
set -e # 遇到错误立即停止

# ==========================================
# Configuration
# ==========================================
REPO_URL="https://github.com/A-Archer/Cloud-Computing-Project-Fall25.git"
BRANCH="Zeli_Ma_test"
PROJECT_DIR="SimAI_MARC_Run"

# 定义关键路径
NS3_SCRATCH="ns-3-alibabacloud/simulation/scratch"
BUILD_SCRATCH="astra-sim-alibabacloud/extern/network_backend/ns3-interface/simulation/build/scratch"
PLOT_SCRIPTS_DIR="scripts" # 假设您把 py 文件放在了这里

echo "========================================================"
echo "   MARC Algorithm: Quick Start & Reproduction Script    "
echo "========================================================"

# ==========================================
# 1. Clone & Initialize (环境准备)
# ==========================================
if [ -d "$PROJECT_DIR" ]; then
    echo "[1/5] Cleaning existing directory..."
    rm -rf "$PROJECT_DIR"
fi

echo "[1/5] Cloning repository..."
git clone -b "$BRANCH" "$REPO_URL" "$PROJECT_DIR"
cd "$PROJECT_DIR"
git submodule update --init --recursive

# 检查 Python 依赖
if ! python3 -c "import matplotlib, pandas" &> /dev/null; then
    echo "Error: Python libraries 'matplotlib' and 'pandas' are required."
    exit 1
fi

# ==========================================
# 2. Build (使用官方脚本构建)
# ==========================================
echo "[2/5] Building SimAI with MARC integration..."
# build.sh 会自动处理文件复制、依赖链接和编译
./scripts/build.sh -c ns3

echo "   -> Build Complete."

# ==========================================
# 3. Verification (功能验证)
# ==========================================
echo "[3/5] Verifying Implementation..."

# A. 验证底层数据平面 (Data Plane)
echo "   -> Running Data Plane Verification (verify_forwarding)..."
# 查找生成的可执行文件 (文件名包含版本号，使用 find 定位)
EXE_VERIFY=$(find "$BUILD_SCRATCH" -name "*verify_forwarding*" -type f -executable | head -n 1)

if [ -z "$EXE_VERIFY" ]; then
    echo "Error: verify_forwarding executable not found. Build failed?"
    exit 1
fi
$EXE_VERIFY

# B. 验证控制平面 (Control Plane)
echo -e "\n   -> Running Control Plane Verification (Spectrum-X Topology)..."
# 生成拓扑
python3 ./astra-sim-alibabacloud/inputs/topo/gen_Topo_Template.py -topo Spectrum-X -g 128 -gt A100 -bw 100Gbps -nvbw 2400Gbps > /dev/null

# 运行仿真并抓取 MARC 控制器日志
EXE_ASTRA=$(find "$BUILD_SCRATCH" -name "*AstraSimNetwork*" -type f -executable | head -n 1)
AS_SEND_LAT=3 AS_NVLS_ENABLE=1 $EXE_ASTRA \
    -t 16 -w ./example/microAllReduce.txt \
    -n ./Spectrum-X_128g_8gps_100Gbps_A100 \
    -c astra-sim-alibabacloud/inputs/config/SimAI.conf 2>&1 | grep "MARC-Ctrl"

# ==========================================
# 4. Performance Benchmark (生成数据)
# ==========================================
echo -e "\n[4/5] Running Performance Experiments..."

# A. 生成 MARC 实测数据 (marc_results.csv)
echo "   -> Generating Real Measurement Data (marc_perf_test)..."
EXE_PERF=$(find "$BUILD_SCRATCH" -name "*marc_perf_test*" -type f -executable | head -n 1)
$EXE_PERF > marc_results.csv

# B. 生成 Ring 基准数据 (ring_results.csv)
echo "   -> Generating Baseline Data (SimAI Sweep)..."
echo "Size_MB,CCT_ns" > ring_results.csv
cp ./example/microAllReduce.txt ./example/microAllReduce.bak

# 定义测试大小
SIZES=(2097152 4194304 8388608 16777216 33554432 67108864 134217728 268435456 536870912)
LABELS=("2MB" "4MB" "8MB" "16MB" "32MB" "64MB" "128MB" "256MB" "512MB")

for i in "${!SIZES[@]}"; do
    SIZE=${SIZES[$i]}
    LABEL=${LABELS[$i]}
    # 修改 workload
    awk -v sz="$SIZE" '/ALLREDUCE/ {$5=sz} 1' ./example/microAllReduce.bak > ./example/microAllReduce.txt
    # 运行仿真
    AS_SEND_LAT=3 AS_NVLS_ENABLE=1 $EXE_ASTRA \
        -t 16 -w ./example/microAllReduce.txt \
        -n ./Spectrum-X_128g_8gps_100Gbps_A100 \
        -c astra-sim-alibabacloud/inputs/config/SimAI.conf > run_temp.log 2>&1
    
    # 提取时间
    if [ -f "ncclFlowModel_EndToEnd.csv" ]; then
        CCT=$(grep "total time" ncclFlowModel_EndToEnd.csv | tail -n 1 | awk -F'total time,' '{print $2}' | tr -d '\r\n')
    else
        CCT="0"
    fi
    if [ -z "$CCT" ]; then CCT="0"; fi
    echo "$LABEL,$CCT" >> ring_results.csv
done
mv ./example/microAllReduce.bak ./example/microAllReduce.txt # 恢复文件

# ==========================================
# 5. Visualization (绘图)
# ==========================================
echo "[5/5] Generating Plots..."

# 检查脚本目录是否存在
if [ ! -d "$PLOT_SCRIPTS_DIR" ]; then
    echo "Warning: Directory '$PLOT_SCRIPTS_DIR' not found. Creating dummy scripts for demonstration..."
    mkdir -p "$PLOT_SCRIPTS_DIR"
    # 这里可以放入之前的 cat <<EOF ... 代码作为 fallback，或者报错退出
    # 假设您已经把 plot_real.py 和 plot_projected.py 放入了 repo 的 scripts/ 目录
fi

# 运行绘图脚本 (假设脚本会读取当前目录下的 csv)
if [ -f "$PLOT_SCRIPTS_DIR/plot_real.py" ]; then
    python3 "$PLOT_SCRIPTS_DIR/plot_real.py"
    echo "   -> Generated Figure A (Real Measurement)"
else
    echo "Error: $PLOT_SCRIPTS_DIR/plot_real.py not found."
fi

if [ -f "$PLOT_SCRIPTS_DIR/plot_projected.py" ]; then
    python3 "$PLOT_SCRIPTS_DIR/plot_projected.py"
    echo "   -> Generated Figure B (System Projection)"
else
    echo "Error: $PLOT_SCRIPTS_DIR/plot_projected.py not found."
fi

echo "========================================================"
echo "SUCCESS! Check the generated .png files."
echo "========================================================"
