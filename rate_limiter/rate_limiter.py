from flask import Flask, request, jsonify
from opensearchpy import OpenSearch

app = Flask(__name__)

os_client = OpenSearch(
    hosts=[{'host': 'opensearch', 'port': 9200}],
    http_auth=('admin', 'BkK8[(SdJ*,#&G4g'),
    use_ssl=False,
)

def get_request_count(spiffe_id, path):
    query = {
        "query": {
            "bool": {
                "must": [
                    {"term": {"spiffe_id.keyword": spiffe_id}},
                    {"term": {"path.keyword": path}}
                ]
            }
        }
    }
    response = os_client.search(index="envoy_access_log", body=query)
    return response['hits']['total']['value']

@app.route('/rate_limit', methods=['POST'])
def rate_limit():
    data = request.json

    print("DATA: ", data)
    spiffe_id = data['descriptors'][0]['entries'][0]['value']
    path = data['descriptors'][0]['entries'][1]['value']

    request_count = get_request_count(spiffe_id, path)
    limit = 10 

    if request_count < limit:
        return jsonify({"overall_code": "OK"})
    else:
        return jsonify({"overall_code": "OVER_LIMIT"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)

