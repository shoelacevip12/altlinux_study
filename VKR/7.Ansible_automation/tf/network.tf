# Общая облачная сеть
resource "yandex_vpc_network" "skv" {
  name = "skv-fops39-${var.lab15_5}"
}

# Подсеть zone D
resource "yandex_vpc_subnet" "skv-locnet-d" {
  name           = "skv-fops-${var.lab15_5}-ru-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.skv.id
  v4_cidr_blocks = ["10.10.10.192/26"]
  route_table_id = yandex_vpc_route_table.route.id
}

# Сеть под NAT для исходящего трафика
resource "yandex_vpc_gateway" "nat-gateway" {
  name = "fops-gateway-${var.lab15_5}"
  shared_egress_gateway {}
}

# Шлюз для выхода в WAN
resource "yandex_vpc_route_table" "route" {
  name       = "fops-route-table-${var.lab15_5}"
  network_id = yandex_vpc_network.skv.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gateway.id
  }
}