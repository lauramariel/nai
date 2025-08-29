PC_ADDRESS = "@@{PC_ADDRESS}@@"
PC_PORT = "@@{PC_PORT}@@"
PC_USERNAME = "@@{CRED_PC.username}@@" 
PC_PASSWORD = "@@{CRED_PC.secret}@@"
DOMAIN = "@@{DOMAIN}@@"
NUS_OBJ_NAME = "@@{NUS_OBJ_NAME}@@"

import requests, base64, boto3
from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

BASIC_AUTH = "{}:{}".format(PC_USERNAME,PC_PASSWORD).encode("utf-8")
B64_AUTH = base64.b64encode(BASIC_AUTH).decode()

PC_URL = "https://{}:{}".format(PC_ADDRESS,PC_PORT)

HEADERS = {
    "Authorization": "Basic {}".format(B64_AUTH),
    "Content-Type": "application/json"
}

def get_directory_services(offset=0, length=5):
    api_endpoint = "/".join([
        PC_URL,
        "oss/pc_proxy/directory_services/list",]
    )

    payload = {
        "offset": offset,
        "length": length
    }

    try:
        resp = requests.post(
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
    
def get_directory_service_by_domain(domain):
    directory_services = get_directory_services()

    return next(
        (idp for idp in directory_services["entities"] if idp["status"]["resources"]["domain_name"] == domain), 
        None)

def create_iam_user(username, email, idp_id="", access_key_name="NEXT_API"):
    api_endpoint = "/".join([
        PC_URL,
        "oss/iam_proxy/buckets_access_keys",]
    )

    if not idp_id:
        payload = {"users": [{"type": "external", "username": "admin@nutanix.com"}]}
    else:
        payload = {
            "users": [
                {
                    "type": "ldap",
                    "username": email,
                    "display_name": username,
                    "idp_id": idp_id,
                    "access_key_name": access_key_name,
                }
            ]
        }

    try:
        resp = requests.post(
            url=api_endpoint,
            json=payload,
            headers=HEADERS,
            verify=False
        )
        resp.raise_for_status()

        return resp.json()["users"][0]

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

def create_s3_session(access_key, secret_key, endpoint_url, aws_region='us-east-1'):
    session = boto3.Session(
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        region_name=aws_region,
    )

    endpoint_url = 'http://{}'.format(endpoint_url)
    client = session.client('s3', endpoint_url=endpoint_url)
    resource = session.resource(service_name='s3', endpoint_url=endpoint_url)

    return client, resource
    
objects_instance = get_objects_instance_by_name(NUS_OBJ_NAME)

if "client_access_network_ipv4_range" in objects_instance["status"]["resources"]:
  objects_instance_public_ip = objects_instance["status"]["resources"]["client_access_network_ipv4_range"]["ipv4_start"]
else:
  objects_instance_public_ip = objects_instance["status"]["resources"]["client_access_network_ip_list"][0]

# Iniitalize array to store user objects
#users = []

# Create shared objects access key
username = "admin"
iam_user = create_iam_user(email="admin@nutanix.com",username="admin")
print(iam_user)
shared_objects_access_key = iam_user["buckets_access_keys"][0]["access_key_id"]
shared_objects_secret_key = iam_user["buckets_access_keys"][0]["secret_access_key"]

# Create buckets for adminuser01-adminuser05
for i in range(1,6):
    username = "adminuser0{}".format(i)
    print(f"Creating bucket for {username}")

    # idp = get_directory_service_by_domain(DOMAIN)

    # iam_user = create_iam_user(
    #     email="{}@{}".format(username, DOMAIN),
    #     username=username,
    #     idp_id=idp["metadata"]["uuid"]
    # )

    # access_key = iam_user["buckets_access_keys"][0]["access_key_id"]
    # secret_key = iam_user["buckets_access_keys"][0]["secret_access_key"]

    # print(f"{username} IAM User created")

    try:
        client, resource = create_s3_session(access_key=shared_objects_access_key, secret_key=shared_objects_secret_key, endpoint_url=objects_instance_public_ip)
        resource.create_bucket(Bucket=username)
        print(f"Bucket {username} created")
    except resource.meta.client.exceptions.ClientError as err:
        raise Exception(err)
    
    # user_object = { "username": username, "access_key": access_key, "secret_key": secret_key }
    # users.append(user_object)

print("SHARED_OBJECTS_ACCESS_KEY={}".format(shared_objects_access_key))
print("SHARED_OBJECTS_SECRET_KEY={}".format(shared_objects_secret_key))
print("NUS_OBJ_INSTANCE_IP_ADDRESS={}".format(objects_instance_public_ip))
print(f"OBJECTS_URL=https://{objects_instance_public_ip}/objectsbrowser")