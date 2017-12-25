output "app_external_ip" {
  value = "${google_compute_instance.app.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "app2_external_ip" {
  value = "${google_compute_instance.app-2.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "lb_ip" {
  value = "${google_compute_global_forwarding_rule.default.ip_address}"
}