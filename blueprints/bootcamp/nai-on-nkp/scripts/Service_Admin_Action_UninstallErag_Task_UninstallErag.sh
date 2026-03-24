#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

if [[ @@{ERAG}@@ != "true" ]]; then
    echo "eRAG marked False or unset, skipping"
    exit 0
fi

# --- Variables ---
REPO_DIR="$HOME/Enterprise-RAG"
DEPLOY_DIR="$REPO_DIR/deployment"
VENV="$DEPLOY_DIR/erag-venv"
CONFIG_FILE="inventory/sample/config.yaml"

uninstall_erag() {
    echo "--- Installing erag ---"
    cd "$DEPLOY_DIR"
    "$VENV/bin/ansible-playbook" -u "$USER" playbooks/application.yaml \
        --tags uninstall \
        -e "@./$CONFIG_FILE"        
}

echo "Starting eRAG uninstallation process..."

uninstall_erag

echo "Uninstall Complete!"