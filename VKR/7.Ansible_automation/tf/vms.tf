# Данные об образе ОС
data "yandex_compute_image" "alt" {
  family = "basealt-alt"
}

# Docker Host
resource "yandex_compute_instance" "docker-host" {
  name        = "vkr"
  hostname    = "vkr"
  platform_id = "standard-v2"
  zone        = "ru-central1-d"

  resources {
    cores         = var.host.cores
    memory        = var.host.memory
    core_fraction = var.host.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.alt.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
    ssh-keys           = "skv:${file("~/.ssh/id_skv_VKR_vpn.pub")}"
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.skv-locnet-d.id
    nat        = true
    ip_address = "10.10.10.254"
    security_group_ids = [
      yandex_vpc_security_group.host_sg.id,
      yandex_vpc_security_group.LAN.id
    ]
  }
}