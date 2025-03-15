# Chatbot demo

This is a real time chatbot demo that works with Nutanix Enterprise AI.

## Install Python requirements

    pip install -r requirements.txt

## Run Chatbot app

    streamlit run chat.py

# To build docker image

docker build --platform linux/amd64 -t myregistry.com/chatbot:1.0 .
docker push myregistry.com/chatbot:1.0
