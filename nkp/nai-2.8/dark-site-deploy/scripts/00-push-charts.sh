

# Authenticate to your registry
#helm registry login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD $IMAGE_REGISTRY_URL

# Change to the path where the charts are downloaded on your local system
export CHART_DIR="./nai-helm-charts-2.7.0"

# Push each chart defined in charts.txt to the registry
for CHART in $(grep -v -e '^#' -e '^$' charts.txt); do
    echo "Pushing $CHART_DIR/$CHART..."
    helm push "$CHART_DIR/$CHART" "oci://$IMAGE_REGISTRY_URL"
done