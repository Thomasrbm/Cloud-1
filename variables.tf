variable "region" {
  description = "Région AWS"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "Taille de la VM"
  type        = string
  default     = "t3.micro"
}

variable "volume_size" {
  description = "Taille du disque en Go"
  type        = number
  default     = 20
}