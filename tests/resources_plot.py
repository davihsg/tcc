import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from opensearchpy import OpenSearch
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

es = OpenSearch(
    hosts=[{"host": "localhost", "port": 9200}],
    http_auth=("admin", "BkK8[(SdJ*,#&G4g"),
    use_ssl=True,
    verify_certs=False,
)

start_time_str = "2024-09-29T19:33:12Z"
end_time_str = "2024-09-29T19:42:12Z"
start_time = pd.to_datetime(start_time_str)
end_time = pd.to_datetime(end_time_str)

query = { "query": { "bool": { "must": [ { "range": { "timestamp": { "gte": start_time_str, "lte": end_time_str } } }, { "term": { "container_name.keyword": "dummy-api" } } ] } }, "sort": [ { "timestamp": { "order": "asc" } } ], "_source": [ "timestamp", "cpu_perc", "mem_perc" ] }

# Executa a busca
index_name = "containers"

try:
    response = es.search(index=index_name, body=query, size=10000)
except Exception as e:
    logger.error(f"Erro ao conectar ao OpenSearch: {e}")
    exit()

if not response["hits"]["hits"]:
    logger.info("Nenhum dado encontrado no intervalo de tempo especificado.")
    exit()

timestamps = []
cpu_perc = []
mem_perc = []

for hit in response["hits"]["hits"]:
    source = hit["_source"]
    timestamps.append(source["timestamp"])
    cpu_perc.append(source.get("cpu_perc"))
    mem_perc.append(source.get("mem_perc"))

df = pd.DataFrame(
    {
        "timestamp": pd.to_datetime(timestamps),
        "cpu_perc": cpu_perc,
        "mem_perc": mem_perc,
    }
)

# Definir 'timestamp' como índice
df.set_index("timestamp", inplace=True)

# Agregar os dados a cada 30 segundos
df_resampled = df.resample("30s").quantile(0.90)

# Resetar o índice para que 'timestamp' volte a ser uma coluna
df_resampled.reset_index(inplace=True)

# Calcular o tempo deslocado em relação ao início
df_resampled["time_shifted"] = (
    df_resampled["timestamp"] - start_time
).dt.total_seconds()

# Verificar se o DataFrame não está vazio
if df_resampled.empty:
    logger.info("DataFrame está vazio após a agregação.")
    exit()

# Plota o gráfico
plt.figure(figsize=(12, 6))

plt.plot(df_resampled["time_shifted"], df_resampled["cpu_perc"], label="CPU (%)")
plt.plot(df_resampled["time_shifted"], df_resampled["mem_perc"], label="Memória (%)")

plt.xlabel("Tempo (segundos)")
plt.ylabel("Uso (%)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.ylim(bottom=0)
plt.xlim(left=0, right=(end_time - start_time).total_seconds())
plt.savefig("cpu_memoria_plot.png")
