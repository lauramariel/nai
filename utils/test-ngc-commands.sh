export NGC_CLI_API_KEY=nvapi-<>

ngc config set
ngc registry image info nim/nvidia/nv-embedqa-e5-v5
ngc registry image info nvcr.io/nim/nvidia/nv-rerankqa-mistral-4b-v3

ngc registry image info nvcr.io/nvidia/aiworkflows/rag-application-multiturn-chatbot
ngc registry image info nvcr.io/nvidia/aiworkflows/rag-playground

## validate that you can login via docker
docker login nvcr.io -u '$oauthtoken'

docker pull nvcr.io/nim/nvidia/nv-embedqa-e5-v5:1.0.1
docker pull nvcr.io/nim/nvidia/nv-rerankqa-mistral-4b-v3:1.0.2
docker pull nvcr.io/nvidia/aiworkflows/rag-playground:24.08
docker pull nvcr.io/nvidia/aiworkflows/rag-application-multiturn-chatbot:24.08