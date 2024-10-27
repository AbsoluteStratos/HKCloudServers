# Based on
# https://github.com/terraform-google-modules/terraform-docs-samples/blob/main/compute/basic_vm/main.tf

resource "google_compute_instance" "hollow_knight_vm" {

  name         = var.vm_name
  machine_type = var.machine_type
  zone         = "${var.region}-${var.zone}"
  tags         = ["hk-server", "http-server", "https-server"]

  boot_disk {
    auto_delete = true
    device_name = "${var.vm_name}-ubuntu"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20240904"
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  network_interface {
    access_config {
      network_tier = "STANDARD"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/${var.project}/regions/${var.region}/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  metadata_startup_script  = <<EOF
      ${file("install_docker.sh")}
      usermod -aG docker ${var.username}
    EOF
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "default" {
  name = "hk-tf-port-forward"
  # https://console.cloud.google.com/networking/networks/list
  network  = "default"
  priority = 2000

  direction     = "INGRESS"
  target_tags   = ["hk-server"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "udp"
    ports    = [tostring(var.hkmp_port)]
  }
  allow {
    protocol = "tcp"
    ports    = [tostring(var.hkmw_port)]
  }
}


output "instance_ip_address" {
  value       = google_compute_instance.hollow_knight_vm.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the newly created instance"
}
