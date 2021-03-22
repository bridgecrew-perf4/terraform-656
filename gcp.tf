provider "google" {
  region  = "us-central1"
  project = "my-ansible-class"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "app" {
  name         = "terraform-app"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
 network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
 }
}

resource "google_compute_instance" "db" {
  name         = "terraform-db"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = "default"
  }
}
resource "google_compute_instance" "elasticsearch" {
  name         = "terraform-elasticsearch"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = "default"
  }
}
resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.default.name
  source_tags   = ["db","elasticsearch","app"]
  source_ranges = ["10.128.0.0/16", "10.128.0.0/17", "10.128.0.0/18"]
  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

    target_tags   = ["app", "db"]
    direction     = "INGRESS"

}
resource "google_compute_firewall" "mad-test-firewall100200" {
  name    = "yep-mad-test-firewall100200"
  network = google_compute_network.default.name
   source_tags   = ["app"]
   source_ranges = ["10.128.0.0/18"]

  allow {
     protocol   = "tcp"
     ports      = ["22", "3306"]
   }
}
resource "google_compute_firewall" "mad-test-firewall200300" {
  name    = "yep-mad-test-firewall200300"
  network = google_compute_network.default.name
   source_tags   = ["app"]
   source_ranges = ["10.128.0.0/18"]
   allow {
     protocol   = "tcp"
     ports      = ["22", "9200-9300"]
  }

     target_tags   = ["elasticsearch"]
     direction     = "INGRESS"

}
resource "google_compute_network" "default" {
  name = "test-network"
}
resource "google_compute_network" "mad-test-firewall100200" {
  name = "yep-mad-test-firewall100200"
}
resource "google_compute_network" "mad-test-firewall200300" {
  name = "yep-mad-test-firewall200300"
}
