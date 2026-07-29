locals {
    k8s_nodes = {
        "control-plane" = { id = 110, ip = "192.168.100.10/24" }
        "node-0" = { id = 111, ip = "192.168.100.11/24" }
        "node-1" = { id = 112, ip = "192.168.100.12/24" }
        "node-2" = { id = 113, ip = "192.168.100.13/24" }
    }
}


resource "proxmox_virtual_environment_vm" "k8s_cluster" {
    for_each = local.k8s_nodes

    name = each.key
    node_name = "pve"
    vm_id = each.value.id

    clone {
        vm_id = 100
    }

    cpu {
        cores = 1
        type = "host"
    }

    memory {
        dedicated = 2048
    }

    network_device {
        bridge = "vmbr0"
    }

    initialization {
        ip_config {
            ipv4 {
                address = each.value.ip
                gateway = var.gateway
            }
        }

        dns {
            servers = var.dns_servers
        }

        user_account {
            username = "k8s"
            password = "k8spasswd"
            keys = [
                "${var.ssh_key}"
            ]
        }
    }
} 