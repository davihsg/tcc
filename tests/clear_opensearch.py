import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from opensearchpy import OpenSearch
import time

es = OpenSearch(
    hosts=[{"host": "localhost", "port": 9200}],
    http_auth=("admin", "BkK8[(SdJ*,#&G4g"),
    use_ssl=True,
    verify_certs=False,
)

start_time_str = "2024-09-29T00:54:09Z"

query = {
    "query": {"range": {"timestamp": {"gte": start_time_str}}},
    "sort": [{"timestamp": {"order": "asc"}}],
    "_source": ["timestamp", "cpu_perc", "mem_perc"],
}

# Executa a busca
index_name = "envoy"

try:
    response = es.search(index=index_name, body=query, size=10000)
except Exception as e:
    exit()

if not response["hits"]["hits"]:
    exit()

cnt = 0

for hit in response["hits"]["hits"]:
    doc_id = hit["_id"]
    try:
        es.delete(index=index_name, id=doc_id)
        print(f"Documento {doc_id} excluído com sucesso.")
        cnt += 1
    except Exception as e:
        print(f"Erro ao excluir o documento {doc_id}: {e}")
        exit(1)

    time.sleep(0.2)

    if cnt % 100 == 0:
        print(f"done {cnt}")
