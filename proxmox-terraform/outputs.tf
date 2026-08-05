resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible-k8s/inventory/machines.ini"
  
  content  = <<EOF
[masters]
%{ for name, node in local.k8s_nodes ~}
%{ if node.group == "masters" ~}
${name} ansible_host=${split("/", node.ip)[0]} ansible_user=${var.user} ansible_sudo_pass=${var.password}
%{ endif ~}
%{ endfor ~}

[workers]
%{ for name, node in local.k8s_nodes ~}
%{ if node.group == "workers" ~}
${name} ansible_host=${split("/", node.ip)[0]} ansible_user=${var.user} pod_cidr=10.200.${tonumber(split("-", name)[1])}.0/24 ansible_sudo_pass=${var.password}
%{ endif ~}
%{ endfor ~}

[cluster_dns_resolver]
dns-resolver ansible_host=${var.dns_server} ansible_user=root ansible_sudo_pass=${var.password}


[k8s:children]
masters
workers
cluster_dns_resolver
EOF

  depends_on = [proxmox_virtual_environment_vm.k8s_cluster]
}