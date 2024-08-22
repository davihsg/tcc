import requests


class Client:
    def __init__(self, webdis_address):
        self.webdis_address = webdis_address

    def get(self, key):
        key = key.replace("/", "%2F")

        url = f"{self.webdis_address}/GET/{key}"
        return requests.get(url, verify=False)

    def incr(self, key):
        key = key.replace("/", "%2F")

        url = f"{self.webdis_address}/INCR/{key}"
        return requests.get(url, verify=False)

    def decr(self, key):
        res = self.get(key)
        if res.status_code != 200:
            return res

        body = res.json()

        value = body["GET"]

        if value is None or int(value) == 0:
            return

        key = key.replace("/", "%2F")

        url = f"{self.webdis_address}/DECR/{key}"
        return requests.get(url, verify=False)
