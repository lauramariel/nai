# Cleanup script to delete all objects access keys and user buckets created by blueprint

PC_ADDRESS = "@@{PC_ADDRESS}@@"
PC_PORT = "@@{PC_PORT}@@"
PC_USERNAME = "@@{CRED_PC.username}@@" 
PC_PASSWORD = "@@{CRED_PC.secret}@@"
DOMAIN = "@@{DOMAIN}@@"
NUS_OBJ_NAME = "@@{NUS_OBJ_NAME}@@"

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

def cleanup_bucket(objects_uuid="",bucket_name=""):
    api_endpoint = "/".join([
        PC_URL,
        f"oss/api/nutanix/v3/objectstore_proxy/{objects_uuid}/buckets/{bucket_name}",]
    )

    try:
        resp = requests.delete(
            url=api_endpoint,
            headers=HEADERS,
            verify=False
        )
        resp.raise_for_status()

    except requests.exceptions.HTTPError as err:
        print(resp.text)
        raise Exception(err)

    print(f"Bucket {bucket_name} deleted")


def cleanup_access_keys(user_uuid="", access_key_id=""):
    api_endpoint = "/".join([
        PC_URL,
        f"oss/iam_proxy/users/{user_uuid}/buckets_access_keys/{access_key_id}",])

    try:
        resp = requests.delete(
            url=api_endpoint,
            headers=HEADERS,
            verify=False
        )
        resp.raise_for_status()

    except requests.exceptions.HTTPError as err:
        print(resp.text)
        raise Exception(err)

def get_objects_instances():
    api_endpoint = "/".join([
        PC_URL,
        "oss/api/nutanix/v3/objectstores/list",]
    )

    try:
        resp = requests.get(
            url=api_endpoint,
            headers=HEADERS,
            verify=False
        )
        resp.raise_for_status()

        return resp.json()


    except requests.exceptions.HTTPError as err:
        print(resp.text)
        raise Exception(err)
        
def get_objects_instance_by_name(objects_instance_name):
    objects_instances = get_objects_instances()

    return next(
        (objects for objects in objects_instances["specs"] if objects["status"]["name"] == objects_instance_name), 
        None)

def get_users():
    api_endpoint = "/".join([
        PC_URL,
        f"oss/iam_proxy/users?filter=has_buckets_access_key==true",]
    )

    payload = {
        "offset": 0,
        "length": 20,
    }

    try:
        resp = requests.get(
            url=api_endpoint,
            json=payload,
            headers=HEADERS,
            verify=False
        )
        resp.raise_for_status()
        return resp.json()

    except requests.exceptions.HTTPError as err:
        print(resp.text)
        raise Exception(err)

objects_instance = get_objects_instance_by_name(NUS_OBJ_NAME)
objects_uuid = objects_instance["metadata"]["uuid"]
users = get_users()

# Clean up created access key
if users["length"] > 0:
    for i in range(0,users["length"]):
        user_uuid = users["users"][i]["uuid"]
        access_key_id = users["users"][i]["buckets_access_keys"][0]["access_key_id"]
        print(f"Cleaning up User UUID: {user_uuid}")
        print(f"Cleaning up Access Key ID: {access_key_id}")
        cleanup_access_keys(user_uuid=user_uuid, access_key_id=access_key_id)

# Cleanup buckets for each user
for i in range(1,6):
    cleanup_bucket(objects_uuid=objects_uuid,bucket_name=f"adminuser0{i}")