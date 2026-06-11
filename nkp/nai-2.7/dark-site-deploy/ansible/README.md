# NAI 2.7 Dark Site Deployment — Ansible Playbook

Automates the three-phase dark site installation of NAI 2.7 on NKP using a single Ansible playbook. Replaces `01-install-dependencies.sh`, `02-install-nai.sh`, and `03-post-install.sh`.

## Secrets

Credentials are stored in `vars/secrets.yml`, which is excluded from the repo via `.gitignore`. Copy the example file and fill in your values before running any playbook:

```bash
cp vars/secrets.example.yml vars/secrets.yml
```

## Prerequisites

- `ansible` (2.15+)
- `ansible-galaxy` (bundled with Ansible)
- `helm` (3.x) with OCI registry support enabled
- `kubectl` configured and pointing at your target cluster
- `envsubst` (part of `gettext`)
- `pip3` / Python 3 (the playbook installs the `kubernetes` library automatically via `pre_tasks`)
- TLS cert and key files accessible on the machine running the playbook

## File structure

```
ansible/
├── deploy.yml                                   # Main playbook
├── setup-storage.yml                            # Storage prerequisites (CSI secret + storage class)
├── uninstall.yml                                # Uninstall playbook
├── ansible.cfg                                  # Ansible configuration (interpreter, inventory)
├── inventory.ini                                # Inventory (localhost)
├── requirements.yml                             # Ansible collection dependencies
├── vars/
│   ├── vars.yml                                 # Non-sensitive vars for deploy.yml / uninstall.yml
│   ├── setup-vars.yml                           # Non-sensitive vars for setup-storage.yml
│   ├── secrets.example.yml                      # Credentials template — copy to secrets.yml and fill in
│   └── secrets.yml                              # Sensitive credentials — gitignored, never committed
└── templates/
    ├── darksite-nai-core.yaml.template
    ├── darksite-nai-operators.yaml.template
    └── eg-config-for-gateway-mode.yaml.template
```

Helm chart tarballs are downloaded into the same directory at runtime by the playbook.

## Configuration

Update the relevant files in `vars/` before running:

**`vars/vars.yml`** — non-sensitive deployment config:

| Variable | Description |
|---|---|
| `IMAGE_REGISTRY_URL` | Hostname (and optional path prefix) of your private registry |
| `IMAGE_PULL_SECRET` | Name for the Kubernetes image pull secret (default: `registry-image-pull-secret`) |
| `PROJECT` | Image path prefix in the registry (default: `nutanix`) |
| `NAI_DEFAULT_RWO_STORAGECLASS` | RWO storage class name |
| `NAI_API_RWX_STORAGECLASS` | RWX storage class name |
| `NKP_WORKSPACE_NAMESPACE` | NKP workspace namespace (default: `kommander`) |
| `cert_path` | Absolute path to the TLS certificate (fullchain) |
| `key_path` | Absolute path to the TLS private key |

**`vars/secrets.yml`** — gitignored, copy from `secrets.example.yml` (see [Secrets](#secrets)):

| Variable | Description |
|---|---|
| `REGISTRY_USERNAME` | Registry login username |
| `REGISTRY_PASSWORD` | Registry login password |
| `REGISTRY_EMAIL` | Registry login email |
| `PE_CREDS_STRING` | Prism Element credentials (`ip:port:user:pass`) — used by `setup-storage.yml` |
| `FILES_CREDS_STRING` | Nutanix Files credentials (`ip:port:user:pass`) — used by `setup-storage.yml` |

**`vars/setup-vars.yml`** — only needed if running `setup-storage.yml`:

| Variable | Description |
|---|---|
| `NAI_API_RWX_STORAGECLASS` | Name to give the RWX storage class |
| `NFS_SERVER_NAME` | Nutanix Files server name |
| `NFS_SERVER_FQDN` | Nutanix Files server FQDN |

The Python interpreter path is set in `ansible.cfg` (`interpreter_python`). Update it there if your Python 3.11+ is at a different path.

You can also override any variable at runtime without editing the file:

```bash
ansible-playbook deploy.yml -e "IMAGE_REGISTRY_URL=myregistry.example.com cert_path=/etc/ssl/my.crt key_path=/etc/ssl/my.key"
```

## Setup

Install the required Ansible collection once:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Running the playbook

```bash
ansible-playbook deploy.yml
```

If the required storage class or CSI credentials secret don't already exist on the cluster, run `setup-storage.yml` first. Update `setup-vars.yml` with your Nutanix Files details, then:

```bash
ansible-playbook setup-storage.yml
```

This creates the `nutanix-csi-credentials-files` secret in `ntnx-system` and the RWX storage class. The RWO storage class (`nutanix-volume`) is typically pre-installed on NKP clusters and does not need to be created.

Run preflight checks before deploying to verify cluster prerequisites:

```bash
ansible-playbook deploy.yml --tags preflight
```

This checks that the Prometheus Operator CRDs (`PodMonitor`, `ServiceMonitor`) and both required storage classes are present.

To run only a specific phase:

```bash
ansible-playbook deploy.yml --tags dependencies
ansible-playbook deploy.yml --tags install
ansible-playbook deploy.yml --tags post-install
```

## What the playbook does

### Phase 1 — Install dependencies

Corresponds to `01-install-dependencies.sh`.

1. Creates namespaces: `envoy-gateway-system`, `kserve`, `opentelemetry`.
3. Creates `registry-image-pull-secret` in each namespace.
4. Pulls Helm chart tarballs from the OCI registry (`helm pull`).
5. Renders `eg-config-for-gateway-mode.yaml` from its template using `envsubst`.
6. Installs Envoy Gateway CRDs via `helm template | kubectl apply --server-side --force-conflicts`.
7. Installs Envoy Gateway, KServe CRDs, KServe, and OpenTelemetry Operator via `helm upgrade --install`.

### Phase 2 — Install NAI

Corresponds to `02-install-nai.sh`.

1. Waits for the KServe controller pod to become ready.
2. Creates the `nai-system` namespace and image pull secret.
3. Renders `darksite-nai-operators.yaml` and `darksite-nai-core.yaml` from templates using `envsubst`.
4. Installs `nai-operators` (with `--insecure-skip-tls-verify`).
5. Waits for `redis-standalone` and `nai-clickhouse-operator` pods to be ready.
6. Installs `nai-core` with AI Gateway and Labs enabled (with `--insecure-skip-tls-verify`).

### Phase 3 — Post-install

Corresponds to `03-post-install.sh`.

1. Waits for all pods in `nai-system` to reach Ready state.
2. Creates the `nai-cert` TLS secret from the paths set in `cert_path` and `key_path`.
3. Patches the `nai-ingress-gateway` Gateway resource to reference `nai-cert`.

## Uninstalling

To remove all Helm releases and namespaces:

```bash
ansible-playbook uninstall.yml
```

To uninstall only NAI (nai-core, nai-operators, nai-system) without touching the dependencies:

```bash
ansible-playbook uninstall.yml --tags nai
```

To uninstall only the dependencies (Envoy Gateway, KServe, OpenTelemetry):

```bash
ansible-playbook uninstall.yml --tags dependencies
```

## Notes

- **Idempotency**: Namespace and secret tasks use `state: present` and are safe to re-run. `helm pull` tasks skip download if the tarball already exists. Helm installs use `upgrade --install` so they also re-run safely.
- **Shell tasks**: `helm pull oci://`, the CRD server-side apply pipeline, `nai-operators`/`nai-core` installs (which require `--insecure-skip-tls-verify`), and `kubectl patch` are expressed as `ansible.builtin.shell` tasks because the `kubernetes.core.helm` module does not support those flags or piped operations natively.
- **Templates**: The `.yaml.template` files use `$VAR` shell substitution syntax and are rendered with `envsubst` rather than Ansible's template module, so the template files themselves do not need to be modified.
