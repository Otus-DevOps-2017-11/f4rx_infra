resource "google_compute_instance_group" "reddit-app-group" {
  name        = "reddit-app-group"
  description = "Terraform instance group of reddit app"

  instances = [
    "${google_compute_instance.app.*.self_link}",
  ]

  # Если мы используем count, то можем обращаться по индексу
  //    "${google_compute_instance.app.0.self_link}",
  //    "${google_compute_instance.app.1.self_link}",


  # Вариант с добавлением второй ноды в ручном режиме
  //    "${google_compute_instance.app-2.self_link}",

  named_port {
    name = "reddit-port"
    port = "9292"
  }
  zone = "${var.app_zone}"
}

resource "google_compute_global_forwarding_rule" "reddit-forwarding-rule" {
  name       = "default-rule"
  target     = "${google_compute_target_http_proxy.reddit-http-proxy.self_link}"
  port_range = "80"
}

resource "google_compute_target_http_proxy" "reddit-http-proxy" {
  name        = "test-proxy"
  description = "a description"
  url_map     = "${google_compute_url_map.reddit-url-map.self_link}"
}

resource "google_compute_url_map" "reddit-url-map" {
  name            = "url-map"
  description     = "a description"
  default_service = "${google_compute_backend_service.reddit-backend-service.self_link}"

  //  host_rule {
  //    //    hosts        = ["site.ru"]
  //    hosts        = ["*"]
  //    path_matcher = "allpaths"
  //  }
  //
  //  path_matcher {
  //    name            = "allpaths"
  //    default_service = "${google_compute_backend_service.reddit-backend-service.self_link}"
  //
  //    path_rule {
  //      paths   = ["/*"]
  //      service = "${google_compute_backend_service.reddit-backend-service.self_link}"
  //    }
  //  }
}

resource "google_compute_backend_service" "reddit-backend-service" {
  name        = "default-backend"
  port_name   = "reddit-port"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = "${google_compute_instance_group.reddit-app-group.self_link}"
  }

  health_checks = ["${google_compute_http_health_check.reddit-health-check.self_link}"]
}

resource "google_compute_http_health_check" "reddit-health-check" {
  name               = "reddit-health-check"
  request_path       = "/"
  port               = "9292"
  check_interval_sec = 5
  timeout_sec        = 1
}
