# JMeter Terraform

This repo contains a [JMeter](http://jmeter.apache.org) cluster setup using [Terraform](https://www.terraform.io) and [DigitalOcean](https://www.digitalocean.com).


## Intro

This recipe creates a cluster for load testing applications using JMeter.
The application itself can run in two modes: GUI and non-GUI.
The "real" load tests themselves should be run using a non-GUI mode, the GUI
mode is recommended to be used for creating a test plan and debugging.

In order to provide real alternative to load testing services out there, the slaves
and the master will be created in randomly selected regions.


## Requirements

In order to use it you need to [install Terraform](https://www.terraform.io/downloads.html).
You also need a [DigitalOcean](https://www.digitalocean.com) account and an API key..
To create test plans locally, you should [install JMeter](http://jmeter.apache.org/download_jmeter.cgi) as well.


## Usage

### SSH

First you should generate a dedicated SSH key-pair for JMeter:

``` bash
$ mkdir -p .ssh
$ ssh-keygen -t rsa -b 4096 -f .ssh/jmeter -q -N ""
```

Although you could use your own keys, there are two problems:

- Terraform cannot use password protected private keys which means you would have to store your personal ones unencrypted
- You would have to manually configure the SSH Key on DigitalOcean and get it's Key ID which you can only do via the API

To avoid the issues above we generate a temporary key-pair. The public key will be automatically registered on DigitalOcean,
and be removed when we remove our cluster.


### Configuration

To create DigitalOcean droplets using Terraform you need an API token which you can generate on their [dashboard](https://cloud.digitalocean.com/settings/api/tokens).
Once you have the token you should create a `terraform.tfvars` file and insert the following content:

```
do_token = "TOKEN"
```

Or use the following oneliner:

``` bash
$ echo 'do_token = "TOKEN"' >> terraform.tfvars
```

Other configuration options you can set:

- **public_key:** Path to the public key *(default: .ssh/jmeter.pub)*
- **private_key:** Path to the private key *(default: .ssh/jmeter)*
- **slave_count:** The number of slaves you want to create *(default: 3)*
- **slave_size:** The droplet size of slaves *(default: 512mb)*
- **master_size:** The droplet size of master *(default: 512mb)*
- **allowed_regions:** Allowed regions. Each droplet will be created in a region randomly selected from this list *(default: all regions, except `ams1`)*

A full example configuration:

```
do_token = "TOKEN"
public_key = ".ssh/jmeter.pub"
private_key = ".ssh/jmeter"
slave_count = 3
slave_size = "512mb"
master_size = "512mb"
allowed_regions = [
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
```

Choose the size and count settings based on the expected number and complexity of your tests.


### Setting up the cluster

Let's start!

Before creating thousand of droplets by accident you should check what Terraform wants to do:

``` bash
$ terraform plan
```

It should list all the proposed actions. You should see the following with the default configuration:
`Plan: 6 to add, 0 to change, 0 to destroy.` (1 SSH key + 1 Region selection + 3 Slaves + 1 Master)

If you are confident of the proposed plan, go ahead and apply it:

``` bash
$ terraform apply
```

Depending on the number of slaves, the network load in the datacenters this should take some time from a few minutes to 10-15 minutes,
but since Terraform optimizes the order of creation as much as possible, increasing the number of slaves shouldn't increase
the processing time that much.

When the setup is finished you should see the following:

```
Outputs:

master_address = 1.2.3.4
slave_addresses = [
    2.3.4.1,
    3.4.1.2,
    4.1.2.3
]
```


### Executing load tests

Once you have your cluster up you are ready to run your test plans.

As a first step copy your test plan to the master server:

``` bash
$ scp -i .ssh/jmeter test.jmx root@1.2.3.4:
```

**Pro tip**: Use `-o IdentitiesOnly=yes` if you have multiple SSH keys, otherwise you might get *Too many authentication failures* error.

**Less pro tip**: Use `-oStrictHostKeyChecking=no` to skip checking the host key.

After uploading the test plan to the master host you can login and execute the test:

``` bash
$ ssh -i .ssh/jmeter root@1.2.3.4
# /opt/jmeter/bin/jmeter -n -r -t test.jmx -l results.jtl
```

Parameter explanation:

- `-n`: Run in non-GUI mode
- `-r`: Run on remote servers
- `-t test.jmx`: Use this test plan
- `-l results.jtl`: Save results


When the tests are finished you can download the results using SCP:

``` bash
$ scp -i .ssh/jmeter root@1.2.3.4:results.jtl .
```

Alternatively you can use the [run.sh](run.sh) script from this repository to skip the manual process:

``` bash
$ ./run.sh test.jmx results.jtl
```


### Destroying the cluster

Destroying is always easier than creating which is true in our case too:

``` bash
$ terraform destroy
```

One of the main reasons that DigitalOcean is a good choice for this cluster is their hourly pricing,
allowing you to destroy the droplets after running the tests and only pay for the time you used it.
This makes this solution quite cheap and efficient compared to paid load testing tools,
since you can get nearly the same (if not better) results and flexibility for considerably less money.

Just to show you some numbers: During the two days I created this recipe I spent around $1,
which included testing if the infrastructure works well. The smallest plan at [Loader.io](https://loader.io/pricing)
costs you $99.95 a month.


## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.
