import matplotlib.pyplot as plt
import pandas as pd
import os
import sys

# 配置
INPUT_FILE = 'marc_results.csv'
OUTPUT_IMAGE = 'Figure_A_Real_Measurement.png'

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"[Error] {INPUT_FILE} not found.")
        sys.exit(1)

    try:
        df = pd.read_csv(INPUT_FILE)
        
        # 数据转换: Bytes -> MB
        df['Size_MB'] = df['Size_Bytes'] / (1024 * 1024)
        
        # 生成标签
        def get_label(x):
            if x < 1024*1024: return f"{x/1024:.0f}KB"
            return f"{x/(1024*1024):.0f}MB"
        df['Label'] = df['Size_Bytes'].apply(get_label)

        # 绘图
        plt.figure(figsize=(10, 6))
        
        # Baseline (Serial Unicast)
        plt.plot(df['Size_MB'], df['Baseline_Time'], 
                 marker='o', linestyle='-', color='black', 
                 label='Baseline (Serial Unicast)', linewidth=2, markersize=8)
        
        # MARC (Real Multicast)
        plt.plot(df['Size_MB'], df['MARC_Time'], 
                 marker='s', linestyle='-', color='#800000', # 深红
                 label='MARC (Real Simulation)', linewidth=3, markersize=8)
        
        # 样式
        plt.yscale('log')
        plt.xscale('log')
        plt.xlabel('Message Size', fontsize=14)
        plt.ylabel('Transmission Time (s)', fontsize=14)
        plt.title('Figure A: MARC vs Baseline (NS-3 Real Measurement)', fontsize=16, fontweight='bold', y=1.02)
        plt.grid(True, which="both", ls="-", alpha=0.2)
        plt.legend(fontsize=12)
        
        # 自定义 X 轴
        plt.xticks(df['Size_MB'], df['Label'], fontsize=12, rotation=0)
        plt.yticks(fontsize=12)
        plt.minorticks_off()

        plt.tight_layout()
        plt.savefig(OUTPUT_IMAGE, dpi=300)
        print(f"[Success] Generated: {OUTPUT_IMAGE}")

    except Exception as e:
        print(f"[Error] Plotting failed: {e}")

if __name__ == "__main__":
    main()
