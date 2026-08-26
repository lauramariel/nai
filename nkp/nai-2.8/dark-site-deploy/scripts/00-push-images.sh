#!/bin/bash
#
# NAI Images - Load, Retag, and Push to Private Registry
#
# This script loads NAI container images from a tar bundle, retags them for your
# private registry, and pushes them to the registry.
#
# Prerequisites:
#   - Docker installed and running
#   - Docker logged into the target registry (docker login)
#   - NAI images tar bundle file
#
# Usage:
#   ./push-images-to-registry.sh <registry-url> <project> <tar-file>
#
# Example:
#   ./push-images-to-registry.sh registry.example.com nutanix nai-images-2.8.0.tar
#

set -uo pipefail

# ============================================================================
# Helper Functions
# ============================================================================

# Check if jq is available for optimization
if command -v jq >/dev/null 2>&1; then
    HAS_JQ=true
else
    HAS_JQ=false
fi

# Verify that all images have been uploaded to the registry
verify_images_uploaded() {
    local registry="$1"
    local project="$2"
    local tar_file="$3"

    print_header "Verifying Images Uploaded to Registry"

    # Get image references from tar file (same as in load step)
    local image_refs
    if [ "$HAS_JQ" = true ]; then
        image_refs=$(get_tar_image_refs "$tar_file")
        if [ $? -ne 0 ]; then
            print_error "Failed to read image list from tar file"
            return 1
        fi
    else
        # Fallback: load the tar file to get image list (less efficient)
        print_warning "jq not available, loading tar file to get image list"
        local load_output
        load_output=$(docker load -i "$tar_file" 2>&1)
        image_refs=""
        while IFS= read -r line; do
            if [[ "$line" =~ Loaded\ image:\ (.+)$ ]]; then
                image_refs+="${BASH_REMATCH[1]}"$'\n'
            fi
        done <<< "$load_output"
        # Remove trailing newline
        image_refs="${image_refs%$'\n'}"
    fi

    # Check each image in the registry
    local failed=0
    local total=0
    while IFS= read -r image_ref; do
        [ -z "$image_ref" ] && continue
        total=$((total + 1))

        # For verification, we need to check the target image name
        # Format: nutanix/nai-api:v2.8.0 → registry.example.com/<project>/nai-api:v2.8.0
        if [[ "$image_ref" =~ ^nutanix/(.+)$ ]]; then
            local image_path="${BASH_REMATCH[1]}"
            local target_image="${registry}/${project}/${image_path}"

            print_info "[$total] Checking: $target_image"
            if docker manifest inspect "$target_image" >/dev/null 2>&1; then
                print_success "Found in registry"
            else
                print_error "Not found in registry"
                failed=$((failed + 1))
            fi
        else
            print_warning "Skipping (not in nutanix/* format): $image_ref"
        fi
    done <<< "$image_refs"

    echo ""
    print_header "Verification Summary"
    echo "Total images checked:   $total"
    echo "Successfully verified:  $((total - failed))"
    echo "Failed/Missing:         $failed"

    if [ $failed -eq 0 ]; then
        print_success "All images verified in registry"
        return 0
    else
        print_error "Verification failed for $failed images"
        return 1
    fi
}

# Get image references (repository:tag) from tar file without loading
get_tar_image_refs() {
    local tar_file="$1"
    local tmp_repo
    tmp_repo=$(mktemp) || return 1
    if ! tar -xOf "$tar_file" repositories > "$tmp_repo" 2>/dev/null; then
        rm -f "$tmp_repo"
        return 1
    fi

    # Extract image references (repository:tag) from repositories JSON
    local image_refs
    image_refs=$(jq -r 'to_entries[] | "\(.key):\(.value|keys[])"' "$tmp_repo" 2>/dev/null)
    local status=$?
    rm -f "$tmp_repo"
    if [ $status -ne 0 ]; then
        return 1
    fi
    echo "$image_refs"
}

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

print_success() {
    echo "✓ $1"
}

print_error() {
    echo "✗ ERROR: $1" >&2
}

print_info() {
    echo "→ $1"
}

print_warning() {
    echo "⚠ WARNING: $1" >&2
}

# ============================================================================
# Validate Arguments
# ============================================================================

# Check if user wants to verify images (special mode)
if [ $# -eq 4 ] && [ "$1" = "--verify" ]; then
    REGISTRY="$2"
    PROJECT="$3"
    TAR_FILE="$4"

    # Validate tar file exists
    if [ ! -f "$TAR_FILE" ]; then
        print_error "Tar file not found: $TAR_FILE"
        exit 1
    fi

    # Run verification only
    verify_images_uploaded "$REGISTRY" "$PROJECT" "$TAR_FILE"
    exit $?
fi

# Normal mode: load, retag, and push images
if [ $# -ne 3 ]; then
    echo "Usage: $0 <registry-url> <project> <tar-file>"
    echo "   OR: $0 --verify <registry-url> <project> <tar-file>"
    echo ""
    echo "Arguments:"
    echo "  registry-url    Your private registry URL (e.g., registry.example.com)"
    echo "  project         Project/repository name in the registry (e.g., nutanix)"
    echo "  tar-file        Path to the NAI images tar bundle"
    echo ""
    echo "Examples:"
    echo "  $0 registry.example.com nutanix nai-images-2.8.0.tar"
    echo "  $0 --verify registry.example.com nutanix nai-images-2.8.0.tar"
    echo ""
    exit 1
fi

REGISTRY="$1"
PROJECT="$2"
TAR_FILE="$3"

# Validate tar file exists
if [ ! -f "$TAR_FILE" ]; then
    print_error "Tar file not found: $TAR_FILE"
    exit 1
fi

# ============================================================================
# Configuration
# ============================================================================

print_header "NAI Images - Load, Retag & Push"
echo "Registry:  $REGISTRY"
echo "Project:   $PROJECT"
echo "Tar File:  $TAR_FILE"
echo "Date:      $(date)"

# Arrays to track images
LOADED_IMAGES=()
FAILED_IMAGES=()

# ============================================================================
# Step 1: Load Images from Tar Bundle (Optimized)
# ============================================================================

print_header "Step 1: Loading Images from Tar Bundle"

# Get image names from tar file without loading
print_info "Checking for existing images..."
EXISTING_IMAGES=()
NEW_IMAGES=()

if [ "$HAS_JQ" = true ]; then
    # Get image references (repository:tag) from tar file
    TAR_IMAGES_OUTPUT=$(get_tar_image_refs "$TAR_FILE")
    if [ $? -eq 0 ] && [ -n "$TAR_IMAGES_OUTPUT" ]; then
        while IFS= read -r image_ref; do
            if [ -n "$image_ref" ]; then
                # Check if image already exists locally (including tag)
                if docker image inspect "$image_ref" >/dev/null 2>&1; then
                    EXISTING_IMAGES+=("$image_ref")
                else
                    NEW_IMAGES+=("$image_ref")
                fi
            fi
        done <<< "$TAR_IMAGES_OUTPUT"
    else
        # Fallback to original method if we can't read from tar
        print_warning "Could not read image list from tar file, falling back to full load"
        HAS_JQ=false
    fi
fi

# If we couldn't use the optimized approach, load all images
if [ "$HAS_JQ" = false ] || [ ${#NEW_IMAGES[@]} -eq 0 ] && [ ${#EXISTING_IMAGES[@]} -eq 0 ]; then
    print_info "Loading images from $TAR_FILE..."
    LOAD_OUTPUT=$(docker load -i "$TAR_FILE" 2>&1)

    # Extract loaded image names
    while IFS= read -r line; do
        if [[ "$line" =~ Loaded\ image:\ (.+)$ ]]; then
            LOADED_IMAGES+=("${BASH_REMATCH[1]}")
        fi
    done <<< "$LOAD_OUTPUT"

    if [ ${#LOADED_IMAGES[@]} -eq 0 ]; then
        print_error "No images were loaded from the tar file"
        exit 1
    fi

    print_success "Loaded ${#LOADED_IMAGES[@]} images"
else
    # Load only new images
    if [ ${#NEW_IMAGES[@]} -gt 0 ]; then
        print_info "Found ${#EXISTING_IMAGES[@]} existing images, loading ${#NEW_IMAGES[@]} new images..."

        # Create a temporary tar with only new images would be complex,
        # so we'll load everything but skip already existing ones in processing
        print_info "Loading images from $TAR_FILE..."
        LOAD_OUTPUT=$(docker load -i "$TAR_FILE" 2>&1)

        # Extract loaded image names
        while IFS= read -r line; do
            if [[ "$line" =~ Loaded\ image:\ (.+)$ ]]; then
                LOADED_IMAGES+=("${BASH_REMATCH[1]}")
            fi
        done <<< "$LOAD_OUTPUT"

        if [ ${#LOADED_IMAGES[@]} -eq 0 ]; then
            print_error "No images were loaded from the tar file"
            exit 1
        fi

        print_success "Loaded ${#LOADED_IMAGES[@]} images (${#EXISTING_IMAGES[@]} already existed)"
    else
        print_success "All ${#EXISTING_IMAGES[@]} images already exist locally"
        LOADED_IMAGES=("${EXISTING_IMAGES[@]}")
    fi
fi

# ============================================================================
# Step 2: Retag and Push Images
# ============================================================================

print_header "Step 2: Retagging and Pushing Images"

PUSHED_COUNT=0
TOTAL_IMAGES=${#LOADED_IMAGES[@]}

for source_image in "${LOADED_IMAGES[@]}"; do
    echo ""
    print_info "[$((PUSHED_COUNT + 1))/$TOTAL_IMAGES] Processing: $source_image"
    
    # Retag image for target registry
    # Format: nutanix/nai-api:v2.8.0 → registry.example.com/<project>/nai-api:v2.8.0
    if [[ "$source_image" =~ ^nutanix/(.+)$ ]]; then
        image_path="${BASH_REMATCH[1]}"
        target_image="${REGISTRY}/${PROJECT}/${image_path}"
        
        print_info "Tagging as: $target_image"
        if ! docker tag "$source_image" "$target_image"; then
            print_error "Failed to tag image"
            FAILED_IMAGES+=("$source_image")
            continue
        fi
        
        print_info "Pushing to registry..."
        if docker push "$target_image"; then
            print_success "Pushed successfully"
            ((PUSHED_COUNT++))
        else
            print_error "Failed to push image"
            FAILED_IMAGES+=("$target_image")
        fi
    else
        print_info "Skipping (not in nutanix/* format)"
    fi
done

# ============================================================================
# Summary
# ============================================================================

print_header "Summary"
echo "Total images loaded:    $TOTAL_IMAGES"
echo "Successfully pushed:    $PUSHED_COUNT"
echo "Failed:                 ${#FAILED_IMAGES[@]}"

if [ ${#FAILED_IMAGES[@]} -gt 0 ]; then
    echo ""
    print_error "The following images failed:"
    for img in "${FAILED_IMAGES[@]}"; do
        echo "  - $img"
    done
    echo ""
    exit 1
fi

echo ""
print_success "All images successfully pushed to $REGISTRY/$PROJECT"
echo ""

exit 0
