variable zone {
  description = "Zone"
}

variable db_disk_image {
  description = "Disk image for reddit DB"
  default     = "reddit-db-base"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable mongo_listen_address {
  description = "Mongo Database IP"
  default     = "127.0.0.1"
}
