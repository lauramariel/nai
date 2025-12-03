PC_ADDRESS = "@@{PC_ADDRESS}@@"
PC_PORT = "@@{PC_PORT}@@"
PC_USERNAME = "@@{CRED_PC.username}@@" 
PC_PASSWORD = "@@{CRED_PC.secret}@@"
NUS_FS_NAME = "@@{NUS_FS_NAME}@@"

import requests, base64
from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

BASIC_AUTH = "{}:{}".format(PC_USERNAME,PC_PASSWORD).encode("utf-8")
B64_AUTH = base64.b64encode(BASIC_AUTH).decode()

PC_URL = "https://{}:{}".format(PC_ADDRESS,PC_PORT)

HEADERS = {
    "Authorization": "Basic {}".format(B64_AUTH),
    "Content-Type": "application/json"
}

def get_fs_uuid_by_name(fs_name):
    api_endpoint = "/".join([
        PC_URL,
        "api/files/v4.0.a2/config/file-servers?$filter=name eq '{}'".format(fs_name),
        ]
    )

    try:
        resp = requests.get(
            url=api_endpoint,
            headers=HEADERS,
            verify=False
        )
        resp.raise_for_status()

        data = resp.json()

        if len(data["data"]) == 1:
            return data["data"][0]["extId"]
        else:
            raise Exception("File server not found.")


    except requests.exceptions.HTTPError as err:
        print(resp.text)
        raise Exception(err)

print("NUS_FS_UUID={}".format(get_fs_uuid_by_name(NUS_FS_NAME)))