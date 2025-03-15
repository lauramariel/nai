import base64
import os

# from langchain.schema import HumanMessage
from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI

# Ensure the following env variables are set
# IMAGE_NAME: path to the local image
# NAI_URL: URL to the NAI instance
# NAI_KEY: API Key for endpoint
# NAI_EP: NAI Endpoint Name

filename = os.getenv("IMAGE_NAME")
url = os.getenv("NAI_URL")
api_key = os.getenv("NAI_KEY")
endpoint = os.getenv("NAI_EP")

with open(filename, "rb") as imgfile:
    base64_bytes = base64.b64encode(imgfile.read())
    base64_encoded = base64_bytes.decode()
    data = {
        "type": "image_url",
        "image_url": {
            "url": "data:image/jpeg;base64," + base64_encoded,
        },
    }

model = ChatOpenAI(
    base_url=f"https://{url}/api/v1",
    api_key=f"{api_key}",
    temperature=0.5,
    model=f"{endpoint}",
    max_tokens=1024,
)

messages = [
    HumanMessage(
        content=[
            {"type": "text", "text": "Can you tell me about the city in this picture?"},
            data,
        ]
    )
]

# Instantiate a chat model and invoke it with the messages

response = model.invoke(messages)
print(response.content)
