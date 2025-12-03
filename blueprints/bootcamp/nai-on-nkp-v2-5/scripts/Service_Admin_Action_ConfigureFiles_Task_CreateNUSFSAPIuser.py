PC_ADDRESS = "@@{PC_ADDRESS}@@"
PC_PORT = "@@{PC_PORT}@@"
PC_USERNAME = "@@{CRED_PC.username}@@"
PC_PASSWORD = "@@{CRED_PC.secret}@@"
NUS_FS_UUID = "@@{NUS_FS_UUID}@@"
NUS_FS_API_USER = "@@{NUS_FS_API_USER}@@"
NUS_FS_API_PASSWORD = "@@{NUS_FS_API_PASSWORD}@@"


#from time import sleep as sleep # Ignore this line when copy/paste to Escript

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

def retry_task(task_function, max_retries=3, base_delay=1, max_delay=10, *args, **kwargs):
    retries = 0
    delay = base_delay
    while retries < max_retries:
        try:
            result = task_function(*args, **kwargs)
            return result  # If the task succeeds, return its result
        except Exception as e:
            print("Attempt {} failed:".format(retries + 1), e)
            retries += 1
            if retries < max_retries:
                print("Retrying...")
                sleep(delay)  # Wait for the current delay
                delay = min(delay * 2, max_delay)  # Exponential backoff
    raise Exception("Task failed after {} attempts".format(max_retries))

def create_api_user(fs_uuid, user, password):
    payload = {
        "name": user,
        "password": password
    }

    api_endpoint = "/".join([
        PC_URL,
        "api/files/v4.0.a4/config/file-servers",
        fs_uuid,
        "users",]
    )

    try:
        resp = requests.post(
            url=api_endpoint,
            json=payload,
            headers=HEADERS,
            verify=False
        )
        resp.raise_for_status()

        return "Created user: {}".format(user)

    except requests.exceptions.HTTPError as err:
        error_group = resp.json().get("data", {}).get("error", [{}])[0].get("errorGroup", "")
        if error_group == "USER_ALREADY_EXISTS":
            return "USER_ALREADY_EXISTS"
        print(resp.text)
        raise Exception(err)

try:
    result = retry_task(create_api_user, max_retries=10, base_delay=2, max_delay=15, fs_uuid=NUS_FS_UUID, user=NUS_FS_API_USER, password=NUS_FS_API_PASSWORD)
    print(result)
except Exception as err:
    print("Error:", err)
    raise Exception(err)

