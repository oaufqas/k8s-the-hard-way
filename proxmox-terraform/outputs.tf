resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible-k8s/inventory/machines.ini"
  
  content  = <<EOF
[masters]
%{ for name, node in local.k8s_nodes ~}
%{ if name == "control-plane" ~}
${name} ansible_host=${split("/", node.ip)[0]} ansible_user=${var.user} ansible_sudo_pass=${var.password}
%{ endif ~}
%{ endfor ~}

[workers]
%{ for name, node in local.k8s_nodes ~}
%{ if name != "control-plane" ~}
${name} ansible_host=${split("/", node.ip)[0]} ansible_user=${var.user} pod_cidr=10.200.${tonumber(split("-", name)[1])}.0/24 ansible_sudo_pass=${var.password}
%{ endif ~}
%{ endfor ~}

[k8s:children]
masters
workers
EOF

  depends_on = [proxmox_virtual_environment_vm.k8s_cluster]
}