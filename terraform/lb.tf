resource "google_compute_instance_group" "reddit-app-group" {
  name        = "reddit-app-group"
  description = "Terraform instance group of reddit app"

  instances = [
    "${google_compute_instance.app.self_link}",
    "${google_compute_instance.app-2.self_link}",
  ]

  named_port {
    name = "reddit-port"
    port = "9292"
  }

  zone = "${var.app_zone}"
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "default-rule"
  target     = "${google_compute_target_http_proxy.default.self_link}"
  port_range = "80"
}

resource "google_compute_target_http_proxy" "default" {
  name        = "test-proxy"
  description = "a description"
  url_map     = "${google_compute_url_map.default.self_link}"
}

resource "google_compute_url_map" "default" {
  name            = "url-map"
  description     = "a description"
  default_service = "${google_compute_backend_service.default.self_link}"

  host_rule {
    //    hosts        = ["site.ru"]
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.default.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.default.self_link}"
    }
  }
}

resource "google_compute_backend_service" "default" {
  name        = "default-backend"
  port_name   = "reddit-port"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = "${google_compute_instance_group.reddit-app-group.self_link}"
  }

  health_checks = ["${google_compute_http_health_check.default.self_link}"]
}

resource "google_compute_http_health_check" "default" {
  name               = "test"
  request_path       = "/"
  port               = "9292"
  check_interval_sec = 5
  timeout_sec        = 1
}
