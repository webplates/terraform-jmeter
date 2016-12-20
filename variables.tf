variable "do_token" {
    description = "DigitalOcean token"
}

variable "slave_count" {
    description = "Number of slaves"
    default = 3
}

variable "slave_size" {
    description = "Size of slaves"
    default = "512mb"
}

variable "master_size" {
    description = "Size of master"
    default = "512mb"
}

variable "ssh_key_ids" {
    type = "list"
    description = "SSH Key ID"
}

variable "ssh_private_key" {
    description = "Path to private SSH key"
    default = "~/.ssh/id_rsa"
}
