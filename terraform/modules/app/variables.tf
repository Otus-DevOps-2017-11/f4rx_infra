variable zone {
  description = "Zone"
}

variable app_disk_image {
  description = "Disk image for reddit APP"
  default     = "reddit-app-base"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}
