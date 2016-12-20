provider "digitalocean" {
    token = "${var.do_token}"
}

# Generate list of regions
resource "random_shuffle" "region" {
    input = [
        "ams1",
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
    result_count = "${var.slave_count + 1}"
}

# JMeter servers
resource "digitalocean_droplet" "jmeter_slave" {
    count = "${var.slave_count}"
    image = "ubuntu-14-04-x64"
    name = "jmeter.slave.${count.index}"
    region = "${random_shuffle.region.result[count.index + 1]}"
    size = "${var.slave_size}"
    private_networking = true
    ssh_keys = "${var.ssh_key_ids}"

    connection {
        user = "root"
        type = "ssh"
        private_key = "${file(var.ssh_private_key)}"
        timeout = "2m"
    }

    provisioner "remote-exec" {
        script = "jmeter.sh"
    }

    provisioner "file" {
        source = "jmeter"
        destination = "/etc/init.d/jmeter"
    }

    provisioner "remote-exec" {
        inline = [
            "sed -i -e 's/#server.rmi.create=false/server.rmi.create=false/g' /opt/jmeter/bin/jmeter.properties",
            "chmod +x /etc/init.d/jmeter",
            "/etc/init.d/jmeter start"
        ]
    }
}

output "slave_addresses" {
    value = ["${digitalocean_droplet.jmeter_slave.*.ipv4_address}"]
}


resource "digitalocean_droplet" "jmeter_master" {
    image = "ubuntu-14-04-x64"
    name = "jmeter.master"
    region = "${random_shuffle.region.result[0]}"
    size = "${var.master_size}"
    private_networking = true
    ssh_keys = "${var.ssh_key_ids}"

    connection {
        user = "root"
        type = "ssh"
        private_key = "${file(var.ssh_private_key)}"
        timeout = "2m"
    }

    provisioner "remote-exec" {
        script = "jmeter.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sed -i -e 's/remote_hosts=.*/remote_hosts=${join(",", digitalocean_droplet.jmeter_slave.*.ipv4_address_private)}/g' /opt/jmeter/bin/jmeter.properties"
        ]
    }
}

output "master_address" {
    value = "${digitalocean_droplet.jmeter_master.ipv4_address}"
}
