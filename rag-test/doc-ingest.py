# Updated 2025-03-25
# pip install langchain langchain_huggingface langchain_community bs4 pymilvus
import time

from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import WebBaseLoader
from langchain_community.vectorstores import Milvus
from langchain_huggingface import HuggingFaceEmbeddings

modelPath = "sentence-transformers/all-mpnet-base-v2"
model_kwargs = {}
# Create a dictionary with encoding options, specifically setting 'normalize_embeddings' to False
encode_kwargs = {"normalize_embeddings": True}
milvus_ip = ""  # Specify the IP address of your Milvus DB

# Initialize an instance of HuggingFaceEmbeddings with the specified parameters
print(f"Initializing HuggingFaceEmbeddings with {modelPath}")
start = time.time()
embeddings = HuggingFaceEmbeddings(
    model_name=modelPath,  # Provide the pre-trained model's path
    model_kwargs=model_kwargs,  # Pass the model configuration options
    encode_kwargs=encode_kwargs,  # Pass the encoding options
)
end = time.time()
elapsed = end - start
print(f"Initializing HuggingFaceEmbeddings complete in {elapsed} seconds")

print("Loading from web started")
start = time.time()
loader = WebBaseLoader("https://www.nutanixbible.com/classic")
data = loader.load()
end = time.time()
elapsed = end - start
print(f"Loading from web complete in {elapsed} seconds")

print("Text splitting started")
start = time.time()
text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=0)
docs = text_splitter.split_documents(data)
end = time.time()
elapsed = end - start
print(f"Text splitting complete in {elapsed} seconds")

start = time.time()
print("Embedding started")
vector_db = Milvus.from_documents(
    docs,
    embeddings,
    collection_name="nutanixbible_web",
    connection_args={"host": f"{milvus_ip}", "port": "19530"},
)
end = time.time()
elapsed = end - start
print(f"Embedding complete in {elapsed} seconds")
