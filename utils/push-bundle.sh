for image in $(docker images --format '{{.Repository}}:{{.Tag}}' | grep 'nai' | grep -v $IMAGE_REGISTRY_URL)
do echo "Tagging $image"
docker tag $image $IMAGE_REGISTRY_URL/$(echo $image)
done

for image in $(docker images --format '{{.Repository}}:{{.Tag}}' | grep 'nai' | grep $IMAGE_REGISTRY_URL)
do echo "Pushing $image"
docker push $(echo $image)
done

  