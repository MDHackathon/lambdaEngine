provider "scaleway" {
  organization = "${var.organization}"
  token        = "${var.token}"
  region       = "${var.region}"
}

resource "scaleway_server" "faas" {
  count = 3
  name  = "faas"
  image = "aecaed73-51a5-4439-a127-6d8229847145"
  type  = "start1-s"

  provisioner "remote-exec" {
    inline = [
      "apt-get update && apt-get install -qy docker.io apt-transport-https",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
      "echo 'deb http://apt.kubernetes.io/ kubernetes-jessie main' | tee -a /etc/apt/sources.list.d/kubernetes.list && apt-get update",
      "apt-get update && apt-get install -y kubelet kubeadm kubernetes-cni",
    ]
  }

  connection {
    type = "ssh"
    user = "root"
    private_key = "${file("${pathexpand("~/.ssh/id_rsa")}")}"
  }
}

resource "scaleway_ip" "ip" {
  count = 3
  server = "${scaleway_server.faas.*.id[count.index]}"
}

resource "scaleway_security_group" "http" {
  name        = "http"
  description = "allow HTTP and HTTPS traffic"
}

resource "scaleway_security_group_rule" "http_accept" {
  security_group = "${scaleway_security_group.http.id}"

  action    = "accept"
  direction = "inbound"
  ip_range  = "0.0.0.0/0"
  protocol  = "TCP"
  port      = 80
}

resource "scaleway_security_group_rule" "ssh_accept" {
  security_group = "${scaleway_security_group.http.id}"

  action    = "accept"
  direction = "inbound"
  ip_range  = "0.0.0.0/0"
  protocol  = "TCP"
  port      = 22
}

resource "scaleway_security_group_rule" "https_accept" {
  security_group = "${scaleway_security_group.http.id}"

  action    = "accept"
  direction = "inbound"
  ip_range  = "0.0.0.0/0"
  protocol  = "TCP"
  port      = 443
}
