terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "1.9.5"
    }
  }
}

locals {
  config = yamldecode(file("${path.module}/jumphostvm_config.yaml"))
}

data "nutanix_cluster" "cluster" {
  name = local.config.cluster_name
}
data "nutanix_subnet" "subnet" {
  subnet_name = local.config.subnet_name
}

provider "nutanix" {
  username     = local.config.user
  password     = local.config.password
  endpoint     = local.config.endpoint
  insecure     = true
  wait_timeout = 60
}

#resource "nutanix_image" "machine-image" {
  #name        = "nkp-rocky-9.4-release-1.29.9-20241008013213.qcow2"
  #description = "Terraform deployed image"
  #source_uri  = local.config.source_uri
#}

resource "nutanix_virtual_machine" "nkp-rocky-jumphost" {
  name                 = local.config.name
  cluster_uuid         = data.nutanix_cluster.cluster.id
  num_vcpus_per_socket = local.config.num_vcpus_per_socket
  num_sockets          = local.config.num_sockets
  memory_size_mib      = local.config.memory_size_mib
  guest_customization_cloud_init_user_data = base64encode(file("${path.module}/cloud-init.yaml"))
  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = local.config.image_uuid
    }
    disk_size_mib = local.config.disk_size_mib
  }
  nic_list {
    subnet_uuid = data.nutanix_subnet.subnet.id
  }

  #depends_on = [nutanix_image.machine-image]
}

output "nkp-rocky-jumphost-ip-address" {
  value = nutanix_virtual_machine.nkp-rocky-jumphost.nic_list_status[0].ip_endpoint_list[0].ip
  description = "IP address of the Jump Host vm"
}
