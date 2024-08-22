from flask import Flask, request, jsonify
import alerting
import webdis

app = Flask(__name__)
GLOBAL_KEY = "global_scope"
webdis_client = webdis.Client("https://envoy:8379")


def process_alert(alert: alerting.Alert):
    if alert.global_scope:
        if alert.state == alerting.ACTIVE:
            webdis_client.incr(GLOBAL_KEY)
        elif alert.state == altering.COMPLETED:
            webdis_client.decr(GLOBAL_KEY)

    else:
        if alert.severity < 2:
            # revogate certificates
            app.logger.debug("todo: revogate certificates")

        if alert.state == alerting.ACTIVE:
            webdis_client.incr(alert.spiffe_id)
        elif alert.state == alerting.COMPLETED:
            webdis_client.decr(alert.spiffe_id)


@app.route("/alert", methods=["POST"])
def receive_alert():
    try:
        j = request.get_json()
    except Exception as e:
        return jsonify({"error": f"{str(e)}"}), 400

    body = alerting.PostAlertRequestBody(**j)

    alerts = body.alerts

    for alert in alerts:
        process_alert(alert)

    return jsonify({"message": f"{len(alerts)} alerts processed"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=31415, debug=True)
