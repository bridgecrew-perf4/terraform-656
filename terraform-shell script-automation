provider "google" {
  region      = var.region
  zone        = var.zone
  project     = var.project
  credentials = file(var.credentials)
}
resource "google_compute_network" "testnetwork" {
  name                    = var.vpc-network
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "network-with-private-subnet" {
  name          = var.prv-subnet
  ip_cidr_range = "10.10.20.0/24"
  region        = var.region
  network       = google_compute_network.testnetwork.id
}

resource "google_compute_subnetwork" "network-with-public-subnet" {
  name          = var.pub-subnet
  ip_cidr_range = "10.10.10.0/24"
  region        = var.region
  network       = google_compute_network.testnetwork.id
}

resource "google_compute_firewall" "default" {
  name        = "testnetwork-general-firewall"
  network     = google_compute_network.testnetwork.name

  allow {
    protocol  = "icmp"
  }

  allow {
    protocol  = "tcp"
    ports     = ["22"]
  }
  
  target_tags = ["app"]
}

resource "google_compute_firewall" "pub-to-prv" {
  name    = "testnetwork-fw-pub-to-prv"
  network = google_compute_network.testnetwork.name

  allow {
    protocol = "icmp"
  }  

  allow {
    protocol = "tcp"
    ports    = ["22", "3306"]
  }

  source_tags = ["app"]
  target_tags = ["db"]
}

data "google_compute_lb_ip_ranges" "ranges" {
}

resource "google_compute_firewall" "loadbalancer" {
  name    = "fw-rule-loadbalance-to-${var.app-name}"
  network = google_compute_network.testnetwork.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "130.211.0.0/22", "35.191.0.0/16"]
  target_tags = ["app"]
}


resource "google_compute_router" "router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.testnetwork.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_instance_template" "app-template" {
  name          = var.app-template
  machine_type  = "e2-medium"
  region        = var.region
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  tags = ["app", "http"]
  disk {
    source_image  = var.centos-7
    auto_delete   = true
    boot          = true
  }

  metadata = {
    startup-script = file(var.app-script-path)
  }
  
  network_interface {
    subnetwork  = google_compute_subnetwork.network-with-public-subnet.name
    access_config {
      // EPHEMERAL IP
     }
  }
}

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 30
  timeout_sec         = 25
  healthy_threshold   = 2
  unhealthy_threshold = 10

  tcp_health_check {
    port = "22"
  }
}

resource "google_compute_region_instance_group_manager" "app-group" {
  name = "${var.app-name}-instance-group-manager"

  base_instance_name  = "${var.app-name}-app"
  region              = var.region
  
  version {
    instance_template = google_compute_instance_template.app-template.id
  }

  target_size = 0

  named_port {
    name      = "custom-ssh"
    port      = 22
  }

  named_port {
    name      = "http"
    port      = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 600
  }
}

resource "google_compute_region_autoscaler" "autoscaler" {
 name   = "my-autoscaler"
 target = google_compute_region_instance_group_manager.app-group.id

 autoscaling_policy {
   max_replicas    = 2
   min_replicas    = 1
   cooldown_period = 600
   cpu_utilization {
      target = 0.85
    }

 }
}

resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name = "${var.app-name}-global-forwarding-rule"
  target      = google_compute_target_http_proxy.target_http_proxy.id
  port_range  = "80"
}

resource "google_compute_backend_service" "backend_service" {
  name = "${var.app-name}-backend-service"
  port_name = "http"
  protocol  = "HTTP"
  
  health_checks = [google_compute_health_check.autohealing.self_link]

  backend {
      group = google_compute_region_instance_group_manager.app-group.instance_group
      balancing_mode   = "UTILIZATION"
      capacity_scaler  = 1.0
  }
}

resource "google_compute_url_map" "url-map" {
  name = "${var.app-name}-load-balancer"
  
  default_service = google_compute_backend_service.backend_service.id
}

resource "google_compute_target_http_proxy" "target_http_proxy" {
  name    = "${var.app-name}-proxy"
  url_map = google_compute_url_map.url-map.id
}

resource "google_compute_global_forwarding_rule" "global_forwarding_rule_http" {
  name        = "${var.app-name}-global-forwarding-rule-http"
  target      = google_compute_target_http_proxy.target_http_proxy.id
  port_range  = "80"
}

resource "google_compute_backend_service" "backend_service_http" {
  name = "${var.app-name}-backend-service-http"
 
  port_name = "http"
  protocol  = "HTTP"

  health_checks = [google_compute_health_check.autohealing.self_link]

  backend {
      group       = google_compute_region_instance_group_manager.app-group.instance_group
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
}

resource "google_compute_url_map" "url-map-http" {
  name = "${var.app-name}-load-balancer-http"
  
  default_service = google_compute_backend_service.backend_service_http.id
}

resource "google_compute_instance" "db-mysql" {
  name         = "${var.app-name}-db-mysql"
  machine_type = "n1-standard-1"
  
  tags = ["db", "mysql"]

  boot_disk {
    initialize_params {
      image = var.centos-7
    }
  }
  metadata = {
    startup-script = file(var.db-script-path)
  }

  network_interface {
    subnetwork  = google_compute_subnetwork.network-with-private-subnet.name
  }
}

output "load-balancer-HTTP-ip-address" {
  value = google_compute_global_forwarding_rule.global_forwarding_rule.ip_address
}
