#!/usr/bin/env bash
set -euo pipefail

IMAGES_FILE="images.txt"
OUTPUT_SCRIPT="migrate-images.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <destination_registry> [--pull] [--tag] [--push] [--dest-path <path>] [--login-source <registry>...]"
  exit 1
fi

DST_REGISTRY="$1"
shift

DO_PULL=false
DO_TAG=false
DO_PUSH=false
DEST_PATH=""
LOGIN_SOURCES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pull) DO_PULL=true ;;
    --tag)  DO_TAG=true ;;
    --push) DO_PUSH=true ;;
    --dest-path)
      DEST_PATH="$2"
      shift
      ;;
    --login-source)
      LOGIN_SOURCES+=("$2")
      shift
      ;;
    *)
      echo "Unknown flag: $1"
      exit 1
      ;;
  esac
  shift
done

# Normalize destination path
DEST_PATH="${DEST_PATH#/}"
DEST_PATH="${DEST_PATH%/}"

# Default to all actions
if ! $DO_PULL && ! $DO_TAG && ! $DO_PUSH; then
  DO_PULL=true
  DO_TAG=true
  DO_PUSH=true
fi

{
  echo '#!/usr/bin/env bash'
  echo 'set -euo pipefail'
  echo

  # Login to source registries first (if any)
  if (( ${#LOGIN_SOURCES[@]} )); then
    for REG in "${LOGIN_SOURCES[@]}"; do
      echo "docker login $REG"
    done
  fi
  # Login to destination registry
  echo "docker login ${DST_REGISTRY}"

} > "${OUTPUT_SCRIPT}"

while IFS= read -r IMAGE || [[ -n "$IMAGE" ]]; do
  [[ -z "$IMAGE" ]] && continue

  # Strip the source registry (everything before first /)
  IMAGE_NO_REGISTRY="${IMAGE#*/}"

  # Build destination image
  if [[ -n "$DEST_PATH" ]]; then
    DST_IMAGE="${DST_REGISTRY}/${DEST_PATH}/${IMAGE_NO_REGISTRY}"
  else
    DST_IMAGE="${DST_REGISTRY}/${IMAGE_NO_REGISTRY}"
  fi

  {
    echo
    echo "echo \"Processing ${IMAGE}\""
    $DO_PULL && echo "docker pull ${IMAGE}"
    $DO_TAG  && echo "docker tag ${IMAGE} ${DST_IMAGE}"
    $DO_PUSH && echo "docker push ${DST_IMAGE}"
  } >> "${OUTPUT_SCRIPT}"

done < "${IMAGES_FILE}"

chmod +x "${OUTPUT_SCRIPT}"

echo "Generated ${OUTPUT_SCRIPT}"
echo "Options: pull=${DO_PULL}, tag=${DO_TAG}, push=${DO_PUSH}, dest-path=${DEST_PATH:-<none>}, login-sources=${LOGIN_SOURCES[*]:-<none>}"
