variable "dz" {
  type    = string
  default = "lab7-openvpn"
}

variable "cloud_id" {
  type    = string
  default = "b1gkumrn87pei2831blp"
}
variable "folder_id" {
  type    = string
  default = "b1g7qviodfc9v4k81sr5"
}

variable "srv" {
  type = map(number)
  default = {
    cores         = 4
    memory        = 4
    core_fraction = 20
  }
}

