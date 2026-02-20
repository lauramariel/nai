# Update model in eRAG

export MODEL_NAME=""
export API_KEY=""

# Get existing config file to patch
kubectl get gmconnectors chatqa -n chatqa -o yaml > chatqa.yaml

# Existing
echo "Before"
yq '.spec.nodes.root.steps[] | select(.name == "Llm")' chatqa.yaml

# Update model
yq e '(.spec.nodes.root.steps[] | select(.name == "Llm") | .internalService.config.LLM_MODEL_NAME) = strenv(MODEL_NAME)' -i chatqa.yaml

# Update API Key if needed
yq e '(.spec.nodes.root.steps[] | select(.name == "Llm") | .internalService.config.LLM_VLLM_API_KEY) = strenv(API_KEY)' -i chatqa.yaml

# New
echo "After"
yq '.spec.nodes.root.steps[] | select(.name == "Llm")' chatqa.yaml

# Update the secret if the API key changed
kubectl get secret vllm-api-key-secret -o yaml | \
yq '.data["LLM_VLLM_API_KEY"] = (strenv(API_KEY) | @base64)' | \
kubectl apply -f -

# Update the chatqa object
kubectl apply -f chatqa.yaml