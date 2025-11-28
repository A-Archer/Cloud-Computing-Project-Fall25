import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
import sys
from matplotlib.ticker import ScalarFormatter, FuncFormatter, LogLocator

# 配置
INPUT_FILE = 'ring_results.csv'
OUTPUT_IMAGE = 'Figure_B_Full_System_Projection.png'
ACCELERATION_FACTOR = 2.1 

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"[Error] {INPUT_FILE} not found.")
        sys.exit(1)
        
    try:
        # 1. 读取数据
        df = pd.read_csv(INPUT_FILE)
        
        # 2. 数据单位修正 (us -> s)
        # 假设 SimAI 输出为微秒
        df['Ring_Seconds'] = df['CCT_ns'].astype(float) / 1e6 
        
        # 计算 MARC 投影
        df['MARC_Seconds'] = df['Ring_Seconds'] / ACCELERATION_FACTOR
        
        # 提取 X 轴数字
        df['Size_Num'] = df['Size_MB'].str.replace('MB', '', regex=False).astype(int)

        # 3. 绘图初始化
        fig, ax = plt.subplots(figsize=(12, 7))
        
        # 设置 Log-Log 坐标轴
        ax.set_yscale('log')
        ax.set_xscale('log')

        # 绘制曲线
        ax.plot(df['Size_Num'], df['Ring_Seconds'], 
                 marker='o', color='black', label='Ring (SimAI Measured)', 
                 linewidth=2, markersize=8)

        ax.plot(df['Size_Num'], df['MARC_Seconds'], 
                 marker='s', color='#800000', label='MARC (Projected)', 
                 linewidth=3, markersize=8)

        # -------------------------------------------------------
        # 4. 坐标轴设置 (显示 X 和 Y 轴)
        # -------------------------------------------------------
        
        # A. Y 轴：格式化为普通数字 (禁用科学计数法)
        def y_format_func(x, pos):
            return f'{x:g}' 
        
        ax.yaxis.set_major_formatter(FuncFormatter(y_format_func))
        ax.yaxis.set_minor_formatter(FuncFormatter(y_format_func))

        # 增加 Y 轴刻度密度
        locmin = LogLocator(base=10.0, subs=(0.2, 0.5, 1.0), numticks=10)
        ax.yaxis.set_minor_locator(locmin)
        ax.yaxis.set_major_locator(LogLocator(base=10.0, numticks=10))
        
        # 设置 Y 轴标签
        ax.set_ylabel('Collective Completion Time (s)', fontsize=14)
        ax.tick_params(axis='y', which='both', labelsize=11)

        # B. X 轴：显示 Message Size
        ax.set_xlabel('Message Size (MB)', fontsize=14)
        ax.set_xticks(df['Size_Num'])
        ax.set_xticklabels(df['Size_MB'], fontsize=12, rotation=45)
        
        # -------------------------------------------------------

        # 装饰
        ax.set_title('Figure B: MARC vs Ring (SimAI Full System)', fontsize=16, fontweight='bold', y=1.02)
        
        # 网格
        ax.grid(True, which="major", ls="-", alpha=0.4, color='gray')
        ax.grid(True, which="minor", ls=":", alpha=0.2, color='gray')
        
        ax.legend(fontsize=12)

        plt.tight_layout()
        plt.savefig(OUTPUT_IMAGE, dpi=300)
        print(f"[Success] Chart updated with full axes: {OUTPUT_IMAGE}")

    except Exception as e:
        print(f"[Error] Plotting failed: {e}")

if __name__ == "__main__":
    main()
