variable "lab15_5" {
  type    = string
  default = "vpn"
}

variable "cloud_id" {
  type    = string
  default = "b1gkumrn87pei2831blp"
}

variable "folder_id" {
  type    = string
  default = "b1g7qviodfc9v4k81sr5"
}

variable "host" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
}