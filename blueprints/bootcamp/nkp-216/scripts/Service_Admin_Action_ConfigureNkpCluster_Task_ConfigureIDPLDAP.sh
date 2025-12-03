#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ~/.env

cat <<EOF | kubectl apply -f -
apiVersion: dex.mesosphere.io/v1alpha1
kind: Connector
metadata:
  name: nutanix-ldap-identity-provider
  namespace: kommander
spec:
  displayName: ${DOMAIN}
  enabled: true
  ldap:
    bindDN: ${BINDDN}
    bindPW: ${BINDPW}
    host: ${LDAP_HOST}:${LDAP_PORT}
    insecureNoSSL: ${NO_SSL}
    insecureSkipVerify: ${SKIP_SSL_VERIFICATION}
    startTLS: ${START_TLS}
    userSearch:
      baseDN: ${LDAP_SEARCH_USERS}
      emailAttr: userPrincipalName
      emailSuffix: ""
      filter: (objectClass=person)
      idAttr: DN
      nameAttr: cn
      scope: sub
      username: sAMAccountName
    groupSearch:
      baseDN: ${LDAP_SEARCH_GROUPS}
      filter: (objectClass=group)
      nameAttr: cn
      scope: ""
      userMatchers:
      - groupAttr: member
        userAttr: DN
  type: ldap
EOF

cat <<EOF | kubectl apply -f -
apiVersion: kommander.mesosphere.io/v1beta1
kind: VirtualGroup
metadata:
  annotations:
    kommander.mesosphere.io/display-name: ntnxlab-ssp-admins
  name: ntnxlab-ssp-admins
spec:
  subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: Group
    name: "oidc:SSP Admins"
---
apiVersion: kommander.mesosphere.io/v1beta1
kind: VirtualGroupClusterRoleBinding
metadata:
  name: ntnxlab-ssp-admins-cluster-federated-admin
spec:
  clusterRoleRef:
    name: kommander-cluster-federated-admin
  placement:
    clusterSelector: {}
  virtualGroupRef:
    name: ntnxlab-ssp-admins
EOF