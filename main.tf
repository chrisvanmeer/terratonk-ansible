terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.26.0"
    }
  }
}

provider "google" {
  project = var.project_name
  region  = var.region
}

resource "google_compute_network" "ansible_network" {
  name = "ansible-network"
}

resource "google_compute_subnetwork" "ansible_subnet" {
  name          = "ansible-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.ansible_network.name
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.ansible_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp"
  network = google_compute_network.ansible_network.id

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["rdp"]
}

resource "google_compute_instance" "ansible_controller" {
  name         = var.ansible_controller_name
  zone         = var.zone
  machine_type = var.ansible_controller_machine_type

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"
  }
  boot_disk {
    initialize_params {
      image = var.ansible_controller_image
    }
  }

  network_interface {
    network    = google_compute_network.ansible_network.id
    subnetwork = google_compute_subnetwork.ansible_subnet.id
    access_config {}
  }

  tags = ["ssh"]
}

resource "google_compute_instance" "ansible_windows_hosts" {
  count        = length(var.ansible_windows_hosts)
  name         = var.ansible_windows_hosts[count.index]
  zone         = var.zone
  machine_type = var.ansible_windows_hosts_machine_type

  boot_disk {
    initialize_params {
      image = var.ansible_windows_hosts_image
    }
  }

  network_interface {
    network    = google_compute_network.ansible_network.id
    subnetwork = google_compute_subnetwork.ansible_subnet.name
    access_config {}
  }

  tags = ["rdp"]
}

# resource "google_dns_record_set" "vm_dns_records" {
#   count        = length(var.ansible_windows_hosts)
#   name         = var.ansible_windows_hosts[count.index]
#   type         = "A"
#   ttl          = 300
#   managed_zone = "<ZONE-ID>"

#   rrdatas = [
#     google_compute_instance.ansible_windows_hosts[count.index].network_interface.0.access_config.0.assigned_nat_ip,
#   ]
# }