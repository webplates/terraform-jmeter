provider "digitalocean" {
    token = "${var.do_token}"
}

# Generate a random list of regions
resource "random_shuffle" "regions" {
    input = ["${var.allowed_regions}"]
    result_count = "${var.slave_count + 1}"
}

# Add a new public key for JMeter
resource "digitalocean_ssh_key" "jmeter" {
    name = "JMeter"
    public_key = "${file(var.public_key)}"
}

# JMeter slaves
resource "digitalocean_droplet" "jmeter_slave" {
    count = "${var.slave_count}"
    image = "ubuntu-14-04-x64"
    name = "jmeter.slave.${count.index}"
    region = "${random_shuffle.regions.result[count.index + 1]}"
    size = "${var.slave_size}"
    ssh_keys = ["${digitalocean_ssh_key.jmeter.id}"]

    connection {
        user = "root"
        type = "ssh"
        private_key = "${file(var.private_key)}"
        timeout = "2m"
        agent = false
    }

    provisioner "remote-exec" {
        script = "install.sh"
    }

    provisioner "file" {
        source = "init"
        destination = "/etc/init.d/jmeter"
    }

    provisioner "remote-exec" {
        inline = [
            "sed -i -e 's/JMETER_IP=.*/JMETER_IP=${self.ipv4_address}/g' /etc/init.d/jmeter",
            "chmod +x /etc/init.d/jmeter",
            "/etc/init.d/jmeter start",
            "sleep 2" # see http://stackoverflow.com/questions/36207752/how-can-i-start-a-remote-service-using-terraform-provisioning
        ]
    }
}

output "slave_addresses" {
    value = ["${digitalocean_droplet.jmeter_slave.*.ipv4_address}"]
}

# JMeter master
resource "digitalocean_droplet" "jmeter_master" {
    image = "ubuntu-14-04-x64"
    name = "jmeter.master"
    region = "${random_shuffle.regions.result[0]}"
    size = "${var.master_size}"
    ssh_keys = ["${digitalocean_ssh_key.jmeter.id}"]

    connection {
        user = "root"
        type = "ssh"
        private_key = "${file(var.private_key)}"
        timeout = "2m"
        agent = false
    }

    provisioner "remote-exec" {
        script = "install.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sed -i -e 's/remote_hosts=.*/remote_hosts=${join(",", digitalocean_droplet.jmeter_slave.*.ipv4_address)}/g' /opt/jmeter/bin/jmeter.properties",
            "sed -i -e '/127.0.1.1.*/d' /etc/hosts"
        ]
    }
}

output "master_address" {
    value = "${digitalocean_droplet.jmeter_master.ipv4_address}"
}
