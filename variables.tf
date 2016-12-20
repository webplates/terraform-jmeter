variable "do_token" {
    description = "DigitalOcean token"
}

variable "public_key" {
    description = "SSH Public Key"
    default = ".ssh/jmeter.pub"
}

variable "private_key" {
    description = "SSH Private Key"
    default = ".ssh/jmeter"
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

variable "allowed_regions" {
    type = "list"
    description = "Allowed regions"
    default = [
        #"ams1",
        "ams2",
        "ams3",
        "blr1",
        "fra1",
        "lon1",
        "nyc1",
        "nyc2",
        "nyc3",
        "sfo1",
        "sfo2",
        "sgp1",
        "tor1"
    ]
}
