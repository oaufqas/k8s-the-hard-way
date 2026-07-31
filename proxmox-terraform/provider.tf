terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

provider "proxmox" {
    endpoint = "https://192.168.100.1:8006/"
    api_token = var.proxmox_api_token
    insecure = true
}