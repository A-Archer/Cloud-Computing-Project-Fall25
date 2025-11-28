#!/bin/bash
set -e
echo "=========================================="
echo " [Step 5] Generating Visualizations"
echo "=========================================="

# 假设您的 py 文件放在 scripts 目录下
SCRIPT_DIR="scripts"

# 检查目录是否存在
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Error: Directory '$SCRIPT_DIR' not found."
    echo "Please create 'scripts' folder and put plot_real.py / plot_projected.py inside."
    exit 1
fi

# --------------------------------------------
# 1. 生成 Figure A (实测对比)
# --------------------------------------------
if [ -f "$SCRIPT_DIR/plot_real.py" ]; then
    echo ">>> Generating Figure A..."
    python3 "$SCRIPT_DIR/plot_real.py"
    echo "   -> Output: Figure_A_Real_Measurement.png"
else
    echo "Warning: $SCRIPT_DIR/plot_real.py not found."
fi

# --------------------------------------------
# 2. 生成 Figure B (全系统投影)
# --------------------------------------------
if [ -f "$SCRIPT_DIR/plot_projected.py" ]; then
    echo ">>> Generating Figure B..."
    python3 "$SCRIPT_DIR/plot_projected.py"
    echo "   -> Output: Figure_B_Full_System_Projection.png"
else
    echo "Warning: $SCRIPT_DIR/plot_projected.py not found."
fi

echo "=========================================="
echo "All Done. Check current directory for .png files."
echo "=========================================="
