
## Notes

Default install looks like this:
```
# From https://nai.howntnx.win/nkp_tutorials/nkp_mcp_lab/nkp_nai_n8n/#install-n8n
mkdir $HOME/n8n
cd $HOME/n8n
git clone https://github.com/n8n-io/n8n-hosting.git
cd n8n-hosting/kubernetes/
kubectl apply -f .
```

The default files from the [cloned repo](https://github.com/n8n-io/n8n-hosting/blob/main/kubernetes/postgres-deployment.yaml) install Postgres 11, which doesn't have the required extension for n8n and it will crash like this

```
[nutanix@nai-dec30-boot ~]$ k logs <n8n-pod-name>
Defaulted container "n8n" out of: n8n, volume-permissions (init)
Last session crashed
Initializing n8n process
n8n ready on ::, port 5678
Migrations in progress, please do NOT stop the process.
Starting migration ChangeDefaultForIdInUserTable1762771264000
Migration "ChangeDefaultForIdInUserTable1762771264000" failed, error: function gen_random_uuid() does not exist
There was an error running database migrations
function gen_random_uuid() does not exist
```

To fix, replace 11 with 13 when installing (this is done in the attached install script)
```
yq -i e '.spec.template.spec.containers[0].image="postgres:13"' postgres-deployment.yaml
```

Or manually add the extension:

```
kubectl exec -it <postgres-pod-name> -- /bin/bash
psql -U changeUser -d postgres
SELECT version();
SELECT gen_random_uuid(); # this will error out
CREATE EXTENSION IF NOT EXISTS pgcrypto;
SELECT gen_random_uuid(); # should work now
```