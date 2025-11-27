import pandas as pd
import matplotlib.pyplot as plt
import os

path = "./ncclFlowModel_EndToEnd.csv"
if not os.path.exists(path):
    path = "/home/yoshino/SimAI/ncclFlowModel_EndToEnd.csv"

# 允许解析错误行，防止列数不一致导致崩溃
df = pd.read_csv(path, on_bad_lines='skip')

lat_cols = [c for c in df.columns if "lat" in c.lower()]
bw_cols = [c for c in df.columns if "bw" in c.lower() or "throughput" in c.lower()]
size_cols = [c for c in df.columns if "size" in c.lower() or "msg" in c.lower()]

lat_col = lat_cols[0] if lat_cols else df.columns[1]
bw_col = bw_cols[0] if bw_cols else None
size_col = size_cols[0] if size_cols else df.columns[0]

plt.figure(figsize=(8,5))
plt.plot(df[size_col], df[lat_col], marker='o', color='royalblue', label="Latency")
plt.xscale("log")
plt.xlabel("Message Size (Bytes)")
plt.ylabel("Latency (μs)")
plt.title("AllReduce Latency on Ring Topology (SimAI)")
plt.grid(True, which="both", linestyle="--", linewidth=0.5)
plt.legend()
plt.tight_layout()
plt.savefig("ring_latency.png", dpi=300)
print("✅ Saved: ring_latency.png")

if bw_col:
    plt.figure(figsize=(8,5))
    plt.plot(df[size_col], df[bw_col], marker='s', color='darkorange', label="Throughput")
    plt.xscale("log")
    plt.xlabel("Message Size (Bytes)")
    plt.ylabel("Throughput (GB/s)")
    plt.title("AllReduce Throughput on Ring Topology (SimAI)")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig("ring_throughput.png", dpi=300)
    print("✅ Saved: ring_throughput.png")
