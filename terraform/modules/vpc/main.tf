resource "google_compute_firewall" "firewall_ssh" {
  description = "Allow SSH for all instances"
  name        = "default-allow-ssh"
  network     = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  priority = 65534

  source_ranges = "${var.source_ranges}"
}
