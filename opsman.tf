resource "google_service_account" "opsman" {
  account_id   = "${var.environment}-opsman"
  display_name = "opsman service account for ${var.environment}"
}

resource "google_service_account_key" "opsman" {
  service_account_id = "${google_service_account.opsman.id}"
}

resource "local_file" "opsman" {
    content  = "${base64decode(google_service_account_key.opsman.private_key)}"
    filename = "${path.module}/google.json"
}

resource "google_project_iam_member" "opsmanInstanceAdmin" {
  project = "${var.project}"
  role    = "roles/compute.instanceAdmin"
  member  = "serviceAccount:${google_service_account.opsman.email}"
}

resource "google_project_iam_member" "opsmanSecurityAdmin" {
  project = "${var.project}"
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.opsman.email}"
}

resource "google_project_iam_member" "opsmanNetworkAdmin" {
  project = "${var.project}"
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.opsman.email}"
}

resource "google_project_iam_member" "opsmanStorageAdmin" {
  project = "${var.project}"
  role    = "roles/compute.storageAdmin"
  member  = "serviceAccount:${google_service_account.opsman.email}"
}

resource "google_project_iam_member" "opsmanViewer" {
  project = "${var.project}"
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.opsman.email}"
}


resource "google_compute_network" "virtnet" {
  name = "${var.environment}-virt-net"
  auto_create_subnetworks = "false"
  routing_mode = "REGIONAL"
  description = "network for Opsman resources"
}

resource "google_compute_subnetwork" "infrastructure" {
  name          = "${var.environment}-subnet-infrastructure-${var.region}"
  ip_cidr_range = "${var.network_infrastructure}"
  network       = "${google_compute_network.virtnet.self_link}"
  region        = "${var.region}"
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.environment}-subnet-main-${var.region}"
  ip_cidr_range = "${var.network_main}"
  network       = "${google_compute_network.virtnet.self_link}"
  region        = "${var.region}"
}

resource "google_compute_subnetwork" "services" {
  name          = "${var.environment}-subnet-services-${var.region}"
  ip_cidr_range = "${var.network_services}"
  network       = "${google_compute_network.virtnet.self_link}"
  region        = "${var.region}"
}

resource "google_compute_instance" "nat-pri" {
  name         = "${var.environment}-nat-gateway-pri"
  machine_type = "n1-standard-4"
  zone         = "${element(var.zones, 0)}"
  tags = ["nat-traverse", "${var.environment}-nat-instance"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1404-trusty-v20180122"
    }
  }
  // Local SSD disk
  scratch_disk {
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.infrastructure.self_link}"
    address = "${cidrhost(var.network_infrastructure,2)}"
    access_config {
      // Ephemeral IP
    }
  }
  metadata {
  }
  can_ip_forward = true
  metadata_startup_script = <<SCRIPT
#!/bin/bash
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
SCRIPT
}

resource "google_compute_instance" "nat-sec" {
  name         = "${var.environment}-nat-gateway-sec"
  machine_type = "n1-standard-4"
  zone         = "${element(var.zones, 1)}"
  tags = ["nat-traverse", "${var.environment}-nat-instance"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1404-trusty-v20180122"
    }
  }
  // Local SSD disk
  scratch_disk {
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.infrastructure.self_link}"
    address = "${cidrhost(var.network_infrastructure,3)}"
    access_config {
      // Ephemeral IP
    }
  }
  metadata {
  }
  can_ip_forward = true
  metadata_startup_script = <<SCRIPT
#!/bin/bash
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
SCRIPT
}

resource "google_compute_instance" "nat-ter" {
  name         = "${var.environment}-nat-gateway-ter"
  machine_type = "n1-standard-4"
  zone         = "${element(var.zones, 2)}"
  tags = ["nat-traverse", "${var.environment}-nat-instance"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1404-trusty-v20180122"
    }
  }
  // Local SSD disk
  scratch_disk {
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.infrastructure.self_link}"
    address = "${cidrhost(var.network_infrastructure,4)}"
    access_config {
      // Ephemeral IP
    }
  }
  metadata {
  }
  can_ip_forward = true
  metadata_startup_script = <<SCRIPT
#!/bin/bash
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
SCRIPT
}

resource "google_compute_route" "nat-pri" {
  name        = "${var.environment}-nat-pri"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.virtnet.self_link}"
  next_hop_instance = "${google_compute_instance.nat-pri.self_link}"
  next_hop_instance_zone = "${element(var.zones, 0)}"
  tags = ["${var.environment}"]
  priority    = 800
}

resource "google_compute_route" "nat-sec" {
  name        = "${var.environment}-nat-sec"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.virtnet.self_link}"
  next_hop_instance = "${google_compute_instance.nat-sec.self_link}"
  next_hop_instance_zone = "${element(var.zones, 1)}"
  tags = ["${var.environment}"]
  priority    = 800
}

resource "google_compute_route" "nat-ter" {
  name        = "${var.environment}-nat-ter"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.virtnet.self_link}"
  next_hop_instance = "${google_compute_instance.nat-ter.self_link}"
  next_hop_instance_zone = "${element(var.zones, 2)}"
  tags = ["${var.environment}"]
  priority    = 800
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.environment}-allow-ssh"
  network = "${google_compute_network.virtnet.self_link}"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = ["allow-ssh"]
}

resource "google_compute_firewall" "http" {
  name    = "${var.environment}-allow-http"
  network = "${google_compute_network.virtnet.self_link}"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = ["allow-http","router"]
}

resource "google_compute_firewall" "https" {
  name    = "${var.environment}-allow-https"
  network = "${google_compute_network.virtnet.self_link}"
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  target_tags = ["allow-https","router"]
}

resource "google_compute_firewall" "all" {
  name    = "${var.environment}-allow-all"
  network = "${google_compute_network.virtnet.self_link}"
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "udp"
  }
  source_tags = ["nat-traverse","${var.environment}","${var.environment}-opsman"]
  target_tags = ["nat-traverse","${var.environment}","${var.environment}-opsman"]
}

resource "google_compute_image" "opsman" {
  name = "opsman"
  raw_disk {
    source = "${var.opsman_image}"
  }
}

resource "google_compute_address" "opsman" {
  name = "${var.environment}-opsman"
}

resource "google_compute_instance" "opsman" {
  name         = "${var.environment}-opsman"
  machine_type = "custom-2-8192"
  zone         = "${element(var.zones, 0)}"
  tags = ["allow-https", "${var.environment}-opsman"]
  service_account {
      scopes = ["cloud-platform"]
      #email  = "${google_service_account.opsman.account_id}"
  }
  boot_disk {
    initialize_params {
      image = "${google_compute_image.opsman.self_link}"
      size  = 100
    }
  }
  // Local SSD disk
  scratch_disk {
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.infrastructure.self_link}"
    address = "${cidrhost(var.network_infrastructure,5)}"
    access_config {
      nat_ip = "${google_compute_address.opsman.address}"
    }
  }
  metadata {
  }
}

resource "google_compute_address" "extra" {
  count = "${length(var.external_ips)}"
  name  = "${var.environment}-${var.external_ips[count.index]}"
}

output "Opsman URL" {
  value = "https://${google_compute_address.opsman.address}"
}

output "External IPs" {
  value = "${formatlist("${var.environment}-%v - %v",  var.external_ips, google_compute_address.extra.*.address)}"
}

output "google config" {
  value = <<OUTPUT

Project ID: ${var.project}
Default deployment tag: ${var.environment}
Auth Json: [copy and paste contents of ./google.json]
OUTPUT
}

output "director config" {
  value = <<OUTPUT

NTP Servers: metadata.google.internal
Enable VM Resurrector Plugin: checked
Enable Post Deploy Scripts: checked
Enable bosh deploy retries: checked
Blobstore Location: internal
Database Location: internal
Director hostname: <blank>
OUTPUT
}

output "Create Availability Zones" {
  value = <<OUTPUT

Zone 1: ${element(var.zones, 0)}
Zone 2: ${element(var.zones, 1)}
Zone 3: ${element(var.zones, 2)}
OUTPUT
}

output "Create Networks" {
  value = <<OUTPUT

Network 1:
- Name: ${var.environment}-main
- Google Network Name: ${var.environment}-virt-net/${var.environment}-subnet-main-${var.region}/${var.region}
- CIDR: ${var.network_main}
- Reserved IP Ranges: ${cidrhost(var.network_main,1)}-${cidrhost(var.network_main,9)}
- DNS: 169.254.169.254
- Gateway: ${cidrhost(var.network_main,1)}
- Availability Zones: ${element(var.zones, 0)},${element(var.zones, 1)},${element(var.zones, 2)}
Network 2:
- Name: ${var.environment}-services
- Service network: checked
- Google Network Name: ${var.environment}-virt-net/${var.environment}-subnet-services-${var.region}/${var.region}
- CIDR: ${var.network_services}
- Reserved IP Ranges: ${cidrhost(var.network_services,1)}-${cidrhost(var.network_services,9)}
- DNS: 169.254.169.254
- Gateway: ${cidrhost(var.network_services,1)}
- Availability Zones: ${element(var.zones, 0)},${element(var.zones, 1)},${element(var.zones, 2)}
Network 3:
- Name: ${var.environment}-infrastructure
- Google Network Name: ${var.environment}-virt-net/${var.environment}-subnet-infrastructure-${var.region}/${var.region}
- CIDR: ${var.network_infrastructure}
- Reserved IP Ranges: ${cidrhost(var.network_infrastructure,1)}-${cidrhost(var.network_infrastructure,9)}
- DNS: 169.254.169.254
- Gateway: ${cidrhost(var.network_infrastructure,1)}
- Availability Zones: ${element(var.zones, 0)},${element(var.zones, 1)},${element(var.zones, 2)}

OUTPUT
}

output "Assign AZs and Networks" {
  value = <<OUTPUT

Singleton Availability Zone: ${element(var.zones, 0)}
Network: ${var.environment}-infrastructure
OUTPUT
}

output "Security" {
  value = <<OUTPUT

OUTPUT
}

output "Syslog" {
  value = <<OUTPUT

OUTPUT
}

output "Resource Config" {
  value = <<OUTPUT
Uncheck "internet connected" on all jobs.
OUTPUT
}
