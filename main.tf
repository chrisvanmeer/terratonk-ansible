terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.26.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.1"
    }
  }
}

## GENERIC

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

## WINDOWS HOSTS

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

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"
  depends_on      = [google_compute_instance.ansible_windows_hosts]
}

resource "null_resource" "reset_windows_password" {
  count = length(var.ansible_windows_hosts)

  triggers = {
    instance_ip = google_compute_instance.ansible_windows_hosts[count.index].network_interface.0.access_config.0.nat_ip
  }

  provisioner "local-exec" {
    command = "gcloud compute reset-windows-password ${var.ansible_windows_hosts[count.index]} --user=${var.ansible_windows_hosts_admin_username} --zone=${var.zone} > password-${var.ansible_windows_hosts[count.index]}.txt"
  }
  depends_on = [time_sleep.wait_30_seconds]
}

resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
      windows_hosts = tomap({
        for instance in google_compute_instance.ansible_windows_hosts :
        instance.name => instance.network_interface.0.access_config.0.nat_ip
      }),
      management = var.ansible_controller_name
    }
  )
  filename   = "./inventory.ini"
  depends_on = [google_compute_instance.ansible_windows_hosts]
}

## CONTROLLER

resource "google_compute_instance" "ansible_controller" {
  name         = var.ansible_controller_name
  zone         = var.zone
  machine_type = var.ansible_controller_machine_type

  metadata = {
    ssh-keys = "${var.ansible_controller_ssh_user}:${file(var.ansible_controller_ssh_pub_key_file)}"
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
  depends_on = [
    google_compute_instance.ansible_windows_hosts,
    local_file.ansible_inventory,
    time_sleep.wait_30_seconds
  ]

  provisioner "file" {
    source      = "./inventory.ini"
    destination = "~/inventory.ini"
    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = var.ansible_controller_ssh_user
      private_key = file(var.ansible_controller_ssh_priv_key_file)
    }
  }
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
