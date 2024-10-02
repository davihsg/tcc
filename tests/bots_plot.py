import json
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import sys

if len(sys.argv) != 2:
    print("Usage: python app.py <user>")
    sys.exit(1)

user = sys.argv[1]

start_time_str = "2024-09-29T18:29:10Z"
end_time_str = "2024-09-29T18:38:10Z"
start_time = pd.to_datetime(start_time_str)
end_time = pd.to_datetime(end_time_str)

resultados_file = f"{user}.json"
with open(resultados_file, "r") as f:
    data = [json.loads(line) for line in f]

timestamps = []
latencies = []
status_codes = []

for result in data:
    timestamp = pd.to_datetime(result["timestamp"])
    latency = result["latency"] / 1e6
    code = result["code"]

    timestamps.append(timestamp)
    latencies.append(latency)
    status_codes.append(code)


df = pd.DataFrame(
    {
        "timestamp": timestamps,
        "latency": latencies,
        "status_code": status_codes,
    }
)

df = df[(df["timestamp"] >= start_time) & (df["timestamp"] <= end_time)]

df["time_shifted"] = (df["timestamp"] - start_time).dt.total_seconds()

interval_size = 10

df["time_interval"] = (df["time_shifted"] // interval_size) * interval_size

grouped = df.groupby(["time_interval", "status_code"]).agg(
    {"latency": ["mean", "median", "max", "min", lambda x: np.percentile(x, 95)]}
)

grouped.columns = ["mean", "median", "max", "min", "p95"]
grouped = grouped.reset_index()

plt.figure(figsize=(12, 6))

status_codes_unique = grouped["status_code"].unique()

for code in status_codes_unique:
    subset = grouped[grouped["status_code"] == code]
    if(code == 403): code = 429
    plt.plot(subset["time_interval"], subset["mean"], label=f"{code}")
    # plt.plot(subset['time_interval'], subset['p95'], label=f'Status {code} - 95º Percentil', marker='x')

plt.xlabel("Tempo (segundos)")
plt.ylabel("Latência (ms)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.ylim(bottom=0)
plt.xlim(left=0, right=(end_time - start_time).total_seconds())

# Salva o gráfico
graph_file = f"{user}_latency.png"
plt.savefig(graph_file, dpi=300)
plt.close()

print(f"Gráfico salvo como '{graph_file}'")
