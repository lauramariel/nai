# THIS FILE IS AUTOMATICALLY GENERATED.
# Disclaimer: Please test this file before using in production.
"""
Generated blueprint DSL (.py)
"""

import json  # no_qa
import os  # no_qa

from calm.dsl.builtins import CalmTask as CalmVarTask
from calm.dsl.builtins import *  # no_qa
from calm.dsl.runbooks import CalmEndpoint as Endpoint

# Secret Variables

BP_CRED_CRED_SSH_KEY = read_local_file("BP_CRED_CRED_SSH_KEY")
BP_CRED_CRED_PC_PASSWORD = read_local_file("BP_CRED_CRED_PC_PASSWORD")
Profile_Nutanix_variable_SSH_PASSWORD = read_local_file(
    "Profile_Nutanix_variable_SSH_PASSWORD"
)
Profile_Nutanix_variable_NKP_LICENSE_KEY = read_local_file(
    "Profile_Nutanix_variable_NKP_LICENSE_KEY"
)
Profile_Nutanix_variable_BINDPW = read_local_file("Profile_Nutanix_variable_BINDPW")
Profile_Nutanix_variable_NUS_FS_API_PASSWORD = read_local_file(
    "Profile_Nutanix_variable_NUS_FS_API_PASSWORD"
)
Profile_Nutanix_variable_DOCKER_PW = read_local_file(
    "Profile_Nutanix_variable_DOCKER_PW"
)
Profile_Nutanix_variable_NAI_NEW_PW = read_local_file(
    "Profile_Nutanix_variable_NAI_NEW_PW"
)
Profile_Nutanix_variable_NAI_DEFAULT_PW = read_local_file(
    "Profile_Nutanix_variable_NAI_DEFAULT_PW"
)

# Credentials
BP_CRED_CRED_SSH = basic_cred(
    "nutanix",
    BP_CRED_CRED_SSH_KEY,
    name="CRED_SSH",
    type="KEY",
    default=True,
    editables={"username": False, "secret": True},
)
BP_CRED_CRED_PC = basic_cred(
    "admin",
    BP_CRED_CRED_PC_PASSWORD,
    name="CRED_PC",
    type="PASSWORD",
    editables={"username": False, "secret": True},
)


NKP_213_ROCKY_95 = vm_disk_package(
    name="NKP_213_ROCKY_95",
    description="",
    config={
        "name": "NKP_213_ROCKY_95",
        "image": {
            "name": "nkp-rocky-9.5-release-1.30.5-20241125163629.qcow2",
            "type": "DISK_IMAGE",
            "source": "http://10.42.194.11/workshop_staging/tradeshows/os_builds/kubernetes/nkp/nkp-rocky-9.5-release-1.30.5-20241125163629.qcow2",
            "architecture": "X86_64",
        },
        "product": {"name": "NKP_213_ROCKY_95", "version": "1.0"},
        "checksum": {},
    },
)


class Admin(Service):
    """Admin machine"""

    NKP_DASHBOARD_URL = CalmVariable.Simple(
        "", label="", is_mandatory=False, is_hidden=False, runtime=False, description=""
    )

    NKP_DASHBOARD_USERNAME = CalmVariable.Simple(
        "", label="", is_mandatory=False, is_hidden=False, runtime=False, description=""
    )

    NKP_DASHBOARD_PASSWORD = CalmVariable.Simple(
        "", label="", is_mandatory=False, is_hidden=False, runtime=False, description=""
    )

    NUS_FS_UUID = CalmVariable.Simple(
        "", label="", is_mandatory=False, is_hidden=False, runtime=False, description=""
    )

    NAI_UI_ENDPOINT = CalmVariable.Simple(
        "", label="", is_mandatory=False, is_hidden=False, runtime=False, description=""
    )

    @action
    def __delete__(type="system"):
        """System action for deleting an application. Deletes created VMs as well"""

        Admin.NkpDeleteClusters(name="Delete NKP clusters")

    @action
    def InstallDeps():

        with parallel() as p0:
            with branch(p0):
                CalmTask.Exec.ssh(
                    name="Add SSH key",
                    filename=os.path.join(
                        "scripts", "Service_Admin_Action_InstallDeps_Task_AddSSHkey.sh"
                    ),
                    target=ref(Admin),
                )
            with branch(p0):
                CalmTask.Exec.ssh(
                    name="Install NKP CLI",
                    filename=os.path.join(
                        "scripts",
                        "Service_Admin_Action_InstallDeps_Task_InstallNKPCLI.sh",
                    ),
                    target=ref(Admin),
                )

                CalmTask.Exec.ssh(
                    name="Create environment variables",
                    filename=os.path.join(
                        "scripts",
                        "Service_Admin_Action_InstallDeps_Task_Createenvironmentvariables.sh",
                    ),
                    target=ref(Admin),
                )

    @action
    def ConfigureFiles():

        CalmTask.SetVariable.escript.py3(
            name="Get NUS FS uuid",
            filename=os.path.join(
                "scripts", "Service_Admin_Action_ConfigureFiles_Task_GetNUSFSuuid.py"
            ),
            target=ref(Admin),
            variables=["NUS_FS_UUID"],
        )

        CalmTask.Exec.escript.py3(
            name="Create NUS FS API user",
            filename=os.path.join(
                "scripts",
                "Service_Admin_Action_ConfigureFiles_Task_CreateNUSFSAPIuser.py",
            ),
            target=ref(Admin),
        )

        CalmTask.Exec.ssh(
            name="Create FS StorageClass manifest",
            filename=os.path.join(
                "scripts",
                "Service_Admin_Action_ConfigureFiles_Task_CreateFSStorageClassmanifest.sh",
            ),
            target=ref(Admin),
        )

    @action
    def InstallNkpCluster():

        CalmTask.Exec.ssh(
            name="Create NKP management cluster",
            filename=os.path.join(
                "scripts",
                "Service_Admin_Action_InstallNkpCluster_Task_CreateNKPmanagementcluster.sh",
            ),
            target=ref(Admin),
        )

    @action
    def ConfigureNkpCluster():

        with parallel() as p0:
            with branch(p0):
                CalmTask.Exec.ssh(
                    name="Configure IDP LDAP",
                    filename=os.path.join(
                        "scripts",
                        "Service_Admin_Action_ConfigureNkpCluster_Task_ConfigureIDPLDAP.sh",
                    ),
                    target=ref(Admin),
                )
            with branch(p0):
                CalmTask.Exec.ssh(
                    name="Install NKP license",
                    filename=os.path.join(
                        "scripts",
                        "Service_Admin_Action_ConfigureNkpCluster_Task_InstallNKPlicense.sh",
                    ),
                    target=ref(Admin),
                )
            with branch(p0):
                CalmTask.Exec.ssh(
                    name="Add LB IPs",
                    filename=os.path.join(
                        "scripts",
                        "Service_Admin_Action_ConfigureNkpCluster_Task_AddLBIPs.sh",
                    ),
                    target=ref(Admin),
                )
            with branch(p0):
                CalmTask.Exec.ssh(
                    name="Enable applications",
                    filename=os.path.join(
                        "scripts",
                        "Service_Admin_Action_ConfigureNkpCluster_Task_Enableapplications.sh",
                    ),
                    target=ref(Admin),
                )
            with branch(p0):
                CalmTask.Exec.ssh(
                    name="Create Files SC",
                    filename=os.path.join(
                        "scripts",
                        "Service_Admin_Action_ConfigureNkpCluster_Task_CreateFilesSC.sh",
                    ),
                    target=ref(Admin),
                )

    @action
    def NotUsed_ConfigureDefaultWorkspace():

        with parallel() as p0:
            with branch(p0):
                CalmTask.Exec.ssh(
                    name="Configure Infrastructure provider",
                    filename=os.path.join(
                        "scripts",
                        "Service_Admin_Action_NotUsed_ConfigureDefaultWorkspace_Task_ConfigureInfrastructureprovider.sh",
                    ),
                    target=ref(Admin),
                )
            with branch(p0):
                CalmTask.Exec.ssh(
                    name="Enable applications",
                    filename=os.path.join(
                        "scripts",
                        "Service_Admin_Action_NotUsed_ConfigureDefaultWorkspace_Task_Enableapplications.sh",
                    ),
                    target=ref(Admin),
                )
                with parallel() as p1:
                    with branch(p1):
                        CalmTask.Exec.ssh(
                            name="Create workload cluster 01",
                            filename=os.path.join(
                                "scripts",
                                "Service_Admin_Action_NotUsed_ConfigureDefaultWorkspace_Task_Createworkloadcluster01.sh",
                            ),
                            target=ref(Admin),
                        )
                    with branch(p1):
                        CalmTask.Exec.ssh(
                            name="Create workload cluster 02",
                            filename=os.path.join(
                                "scripts",
                                "Service_Admin_Action_NotUsed_ConfigureDefaultWorkspace_Task_Createworkloadcluster02.sh",
                            ),
                            target=ref(Admin),
                        )

    @action
    def GetDashboardAccess():

        CalmTask.SetVariable.ssh(
            name="NKP Dashboard Access",
            filename=os.path.join(
                "scripts",
                "Service_Admin_Action_GetDashboardAccess_Task_NKPDashboardAccess.sh",
            ),
            target=ref(Admin),
            variables=[
                "NKP_DASHBOARD_URL",
                "NKP_DASHBOARD_USERNAME",
                "NKP_DASHBOARD_PASSWORD",
            ],
        )

    @action
    def PackageInstall():

        with parallel() as p0:
            with branch(p0):
                Admin.InstallDeps(name="Install NKP dependencies")

                Admin.ConfigureFiles(name="Configure Files for StorageClass")

                Admin.InstallNkpCluster(name="Install NKP management cluster")

                Admin.ConfigureNkpCluster(name="Configure NKP cluster")
                with parallel() as p4:
                    with branch(p4):
                        Admin.InstallNAI(name="InstallNAI")

                        Admin.InstallAISoftware(name="InstallAISoftware")
                    with branch(p4):
                        Admin.GetDashboardAccess(name="NKP dashboard access details")
            with branch(p0):
                Admin.InstallTools(name="Install Tools")

    @action
    def NkpDeleteClusters():

        CalmTask.Exec.ssh(
            name="Delete management cluster",
            filename=os.path.join(
                "scripts",
                "Service_Admin_Action_NkpDeleteClusters_Task_Deletemanagementcluster.sh",
            ),
            target=ref(Admin),
        )

    @action
    def InstallNAI():

        CalmTask.Exec.ssh(
            name="InstallKserve",
            filename=os.path.join(
                "scripts", "Service_Admin_Action_InstallNAI_Task_InstallKserve.sh"
            ),
            target=ref(Admin),
        )

        CalmTask.Exec.ssh(
            name="InstallNAI",
            filename=os.path.join(
                "scripts", "Service_Admin_Action_InstallNAI_Task_InstallNAI.sh"
            ),
            target=ref(Admin),
        )

        CalmTask.SetVariable.ssh(
            name="PostInstall",
            filename=os.path.join(
                "scripts", "Service_Admin_Action_InstallNAI_Task_PostInstall.sh"
            ),
            target=ref(Admin),
            variables=["NAI_UI_ENDPOINT"],
        )

        CalmTask.Exec.ssh(
            name="ConfigureNAI",
            filename=os.path.join(
                "scripts", "Service_Admin_Action_InstallNAI_Task_ConfigureNAI.sh"
            ),
            target=ref(Admin),
        )

    @action
    def InstallTools():

        CalmTask.Exec.ssh(
            name="SetupTools",
            filename=os.path.join(
                "scripts", "Service_Admin_Action_InstallTools_Task_SetupTools.sh"
            ),
            target=ref(Admin),
        )

    @action
    def InstallAISoftware():

        CalmTask.Exec.ssh(
            name="Install Ingress",
            filename=os.path.join(
                "scripts",
                "Service_Admin_Action_InstallAISoftware_Task_InstallIngress.sh",
            ),
            target=ref(Admin),
        )

        CalmTask.Exec.ssh(
            name="Install Flowise",
            filename=os.path.join(
                "scripts",
                "Service_Admin_Action_InstallAISoftware_Task_InstallFlowise.sh",
            ),
            target=ref(Admin),
        )

        CalmTask.Exec.ssh(
            name="Install Langfuse",
            filename=os.path.join(
                "scripts",
                "Service_Admin_Action_InstallAISoftware_Task_InstallLangfuse.sh",
            ),
            target=ref(Admin),
        )


class calm_application_namebootResources(AhvVmResources):

    memory = 8
    vCPUs = 4
    cores_per_vCPU = 1
    disks = [
        AhvVmDisk.Disk.Scsi.cloneFromImageService(
            "nkp-rocky-9.5-release-1.31.4-20250214003015.qcow2", bootable=True
        )
    ]
    nics = [AhvVmNic.NormalNic.ingress("primary", cluster="PHX-POC256")]

    guest_customization = AhvVmGC.CloudInit(
        filename=os.path.join("specs", "calm_application_nameboot_cloud_init_data.yaml")
    )

    power_state = "ON"


class calm_application_nameboot(AhvVm):

    name = "@@{calm_application_name}@@-boot"
    resources = calm_application_namebootResources
    cluster = Ref.Cluster(name="PHX-POC256")


class Admin_Substrate(Substrate):
    """
    Admin AHV Spec
    Default 4 CPU & 16 GB of memory
    """

    account = Ref.Account("NTNX_LOCAL_AZ")
    os_type = "Linux"
    provider_type = "AHV_VM"
    provider_spec = calm_application_nameboot

    readiness_probe = readiness_probe(
        connection_type="SSH",
        disabled=False,
        retries="5",
        connection_port=22,
        address="@@{platform.status.resources.nic_list[0].ip_endpoint_list[0].ip}@@",
        delay_secs="60",
        credential=ref(BP_CRED_CRED_SSH),
    )


class Admin_Package(Package):
    """
    Package install for Admin
    """

    services = [ref(Admin)]

    @action
    def __install__(type="system"):

        Admin.PackageInstall(name="Package Install")


class Admin_Deployment(Deployment):

    min_replicas = "1"
    max_replicas = "1"

    packages = [ref(Admin_Package)]
    substrate = ref(Admin_Substrate)


class Nutanix(Profile):

    deployments = [Admin_Deployment]

    MANAGEMENT_WORKSPACE_APPS = CalmVariable.Simple(
        "nkp-insights,nkp-insights-1.4.4 istio,istio-1.23.3 knative,knative-1.17.0",
        label="Apps to additionally enable in the Management Workspace",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="This need to be updated with every new release. Command to list apps is kubectl get clusterapps. The format of the list is to use comma to separate appdeployment and app name, and the space to separate different apps",
    )

    DEFAULT_WORKSPACE_APPS = CalmVariable.Simple(
        "grafana-logging,grafana-logging-8.9.0 grafana-loki,grafana-loki-0.79.5 kube-prometheus-stack,kube-prometheus-stack-69.1.2 kubecost,kubecost-2.5.2 kubernetes-dashboard,kubernetes-dashboard-7.10.3 logging-operator,logging-operator-5.0.1 nkp-insights-management,nkp-insights-management-1.4.4 prometheus-adapter,prometheus-adapter-4.11.0 rook-ceph,rook-ceph-1.16.2 rook-ceph-cluster,rook-ceph-cluster-1.16.2",
        label="Apps to enable by default in Default Workspace",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="This need to be updated with every new release. Command to list apps is kubectl get clusterapps. The format of the list is to use comma to separate appdeployment and app name, and the space to separate different apps",
    )

    CSI_FILE_SERVER_NAME = CalmVariable.Simple(
        "dummy",
        label="Files instance name for CSI",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    CSI_FILE_SERVER_ENABLE = CalmVariable.WithOptions(
        ["false", "true"],
        label="Enable Files CSI",
        default="false",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    STORAGE_CONTAINER_NAME = CalmVariable.Simple(
        "SelfServiceContainer",
        label="PE storage container for CSI Volumes",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    CONTAINER_REGISTRY_MIRROR = CalmVariable.Simple(
        "registry.nutanixdemo.com/docker.io",
        label="Registry mirror",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    REGISTRY_MIRROR_ENABLE = CalmVariable.WithOptions(
        ["false", "true"],
        label="Enable private registry mirror",
        default="true",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    SSH_PASSWORD = CalmVariable.Simple.Secret(
        Profile_Nutanix_variable_SSH_PASSWORD,
        label="Linux SSH password",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    NKP_LICENSE_KEY = CalmVariable.Simple.Secret(
        Profile_Nutanix_variable_NKP_LICENSE_KEY,
        label="NKP license key",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="",
    )

    DOMAIN = CalmVariable.Simple(
        "ntnxlab.local",
        label="AD domain",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    MGMT_LB_IP_RANGE_USERS_ENDS = CalmVariable.Simple(
        "10.38.35.58",
        label="External IPs for users LB services",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    MGMT_LB_IP_RANGE_USERS_STARTS = CalmVariable.Simple(
        "10.38.35.39",
        label="External IPs for users LB services",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    MGMT_LB_IP_RANGE_ENDS = CalmVariable.Simple(
        "10.38.35.16",
        label="NKP Apps VIP for MetalLB",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    MGMT_LB_IP_RANGE_STARTS = CalmVariable.Simple(
        "10.38.35.16",
        label="NKP Apps VIP for MetalLB",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    CONTROL_PLANE_VIP_ADDRESS = CalmVariable.Simple(
        "10.38.35.15",
        label="Control Plane VIP address",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    NKP_BINARY_URL = CalmVariable.Simple(
        "http://10.42.194.11/workshop_staging/tradeshows/software/nutanix/kubernetes/nkp/nkp_v2.14.0_linux_amd64.tar.gz",
        label="URL for NKP CLI tarball",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    BINDDN = CalmVariable.Simple(
        "cn=Administrator,cn=Users,dc=ntnxlab,dc=local",
        label="LDAP Bind User",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    BINDPW = CalmVariable.Simple.Secret(
        Profile_Nutanix_variable_BINDPW,
        label="LDAP Bind User Password",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="",
    )

    LDAP_HOST = CalmVariable.Simple(
        "10.38.35.6",
        label="LDAP Host",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    LDAP_PORT = CalmVariable.Simple.int(
        "636",
        label="LDAP Port",
        regex="^[\\d]*$",
        validate_regex=False,
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    NO_SSL = CalmVariable.WithOptions(
        ["false", "true"],
        label="NO SSL",
        default="false",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    SKIP_SSL_VERIFICATION = CalmVariable.WithOptions(
        ["false", "true"],
        label="Skip SSL verification",
        default="true",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    START_TLS = CalmVariable.WithOptions(
        ["false", "true"],
        label="Start TLS",
        default="false",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    LDAP_SEARCH_USERS = CalmVariable.Simple(
        "cn=Users,dc=ntnxlab,dc=local",
        label="LDAP Search Users Path",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    LDAP_SEARCH_GROUPS = CalmVariable.Simple(
        "cn=Users,dc=ntnxlab,dc=local",
        label="LDAP Search Groups Path",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    CLUSTER_NAME = CalmVariable.Simple(
        "nkp",
        label="NKP cluster name",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    PC_ADDRESS = CalmVariable.Simple(
        "10.38.35.7",
        label="Prism Central IP address",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    PC_PORT = CalmVariable.Simple.int(
        "9440",
        label="Prism Central Port",
        regex="^[\\d]*$",
        validate_regex=False,
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    MACHINE_TEMPLATE_IMAGE_NAME = CalmVariable.Simple(
        "nkp-rocky-9.5-release-1.31.4-20250214003015.qcow2",
        label="Template name",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    PRISM_ELEMENT_CLUSTER_NAME = CalmVariable.Simple(
        "PHX-POC263",
        label="Prism Element cluster name",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    PE_VIP_ADDRESS = CalmVariable.Simple(
        "10.38.35.37",
        label="Prism Element cluster IP",
        is_mandatory=True,
        is_hidden=False,
        runtime=True,
        description="",
    )

    SUBNET_NAME = CalmVariable.Simple(
        "primary",
        label="Subnet name",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    NUS_FS_API_PASSWORD = CalmVariable.Simple.Secret(
        Profile_Nutanix_variable_NUS_FS_API_PASSWORD,
        label="Files API password",
        is_mandatory=False,
        is_hidden=False,
        runtime=True,
        description="",
    )

    NUS_FS_API_USER = CalmVariable.Simple(
        "csi",
        label="Files API user",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    NUS_FS_NAME = CalmVariable.Simple(
        "files",
        label="",
        is_mandatory=False,
        is_hidden=True,
        runtime=False,
        description="",
    )

    NAI_CORE_VERSION = CalmVariable.Simple(
        "2.2",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description="",
    )

    DOCKER_PW = CalmVariable.Simple.Secret(
        Profile_Nutanix_variable_DOCKER_PW,
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description="",
    )

    DOCKER_USERNAME = CalmVariable.Simple(
        "ntnxsvcgpt",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description="",
    )

    DOCKER_EMAIL = CalmVariable.Simple(
        "laura@nutanix.com",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description="",
    )

    HF_TOKEN = CalmVariable.Simple(
        "asdf",
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description="",
    )

    NAI_NEW_PW = CalmVariable.Simple.Secret(
        Profile_Nutanix_variable_NAI_NEW_PW,
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description="",
    )

    NAI_DEFAULT_PW = CalmVariable.Simple.Secret(
        Profile_Nutanix_variable_NAI_DEFAULT_PW,
        label="",
        is_mandatory=False,
        is_hidden=False,
        runtime=False,
        description="",
    )


class next25nkpnai(Blueprint):
    """[NAI Dashboard](@@(Admin.NAI_UI_ENDPOINT)@@)
    [NKP Console](@@{Admin.NKP_DASHBOARD_URL}@@)

    Credentials:
     - username: @@{Admin.NKP_DASHBOARD_USERNAME}@@
     - password: @@{Admin.NKP_DASHBOARD_PASSWORD}@@

    **NOTE**: It is recommended to configure an identity provider on first login and rotate the dashboard password afterwards ([more info](https://docs.d2iq.com/dkp/@@{DKP_DOC_VERSION}@@/pre-provisioned-verify-install-and-log-in-to-ui#id-(@@{DKP_DOC_VERSION}@@)Pre-provisioned:VerifyInstallandLogintoUI-LogintotheUI))
    """

    services = [Admin]
    packages = [Admin_Package, NKP_213_ROCKY_95]
    substrates = [Admin_Substrate]
    profiles = [Nutanix]
    credentials = [BP_CRED_CRED_SSH, BP_CRED_CRED_PC]
