resource "google_compute_instance" "app-2" {
  name         = "reddit-app-2"
  machine_type = "g1-small"
  zone         = "${var.app_zone}"

  metadata {
    sshKeys = "${data.template_file.ssh_keys.rendered}"
  }

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  network_interface {
    network       = "default"
    access_config = {}
  }

  tags = ["reddit-app"]

  connection {
    type        = "ssh"
    user        = "appuser"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}
