locals {
    k8s_nodes = {
        "control-plane" = { id = 110, ip = "192.168.100.10/24" }
        "node-0" = { id = 111, ip = "192.168.100.11/24" }
        "node-1" = { id = 112, ip = "192.168.100.12/24" }
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
            servers = [ "192.168.100.20" ]
            domain = var.cluster_domain
        }

        user_account {
            username = "k8s"
            password = var.password
            keys = [
                "${var.ssh_key}"
            ]
        }
    }
}


data "proxmox_file" "ubuntu_container_template" {
    node_name    = "pve"
    datastore_id = "local"
    content_type = "vztmpl"
    file_name    = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}


resource "proxmox_virtual_environment_container" "dns-resolver" {
    node_name = "pve"
    vm_id = 120
    unprivileged = true

    features {
        nesting = true
    }

    initialization {
        hostname = "dns-resolver"

        dns {
            servers = [ "1.1.1.1", "8.8.8.8" ]
            domain = var.cluster_domain
        }

        ip_config {
            ipv4 {
                address = "${var.dns_servers[0]}/24"
                gateway = var.gateway
            }
        }

        user_account {
            keys = ["${var.ssh_key}"]
            password = var.password
        }
    }

    network_interface {
        name = "eth0"
        bridge = "vmbr0"
    }

    disk {
        datastore_id = "local-lvm"
        size         = 6
    }

    cpu {
        cores = 1
    }

    memory {
        dedicated = 512
    }

    operating_system {
        template_file_id = data.proxmox_file.ubuntu_container_template.id
        type = "ubuntu"
    }
}