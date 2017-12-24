provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

data "template_file" "ssh_keys" {
  template = "$${key1}\n$${key2}\n$${key3}"
  vars {
    key1 = "appuser:${file(var.public_key_path)}"
    key2 = "appuser1:${file(var.public_key_path)}"
    key3 = "appuser2:${file(var.public_key_path)}"
  }
}

resource "google_compute_instance" "app" {
  name         = "reddit-app"
  machine_type = "g1-small"
  zone         = "${var.app_zone}"

  metadata {
//    sshKeys = "appuser:${file(var.public_key_path)}\nappuser1:${file(var.public_key_path)}"
    sshKeys = "${data.template_file.ssh_keys.rendered}"
  }

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      # другой вариант:
      # image = "reddit-base-1513976435"
      # image = "reddit-base"
      image = "${var.disk_image}"
    }
  }

  # определение сетевого интерфейса
  network_interface {
    # сеть, к которой присоединить данный интерфейс
    network = "default"

    # использовать ephemeral IP для доступа из Интернет
    access_config {}
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

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"

  # Название сети, в которой действует правило
  network = "default"

  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]

  # Правило применимо для инстансов с тегом …
  target_tags = ["reddit-app"]
}
