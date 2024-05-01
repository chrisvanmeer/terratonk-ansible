# terratonk-ansible

## Objective

Deploy a Linux VM and *n* number of Windows VM's with Terraform into Google Cloud Platform.  
All servers will be joined in the same VPC network.
Inbound `tcp/22` and `tcp/3389` is allowed to all servers in the VPC network.

## Pre-requisites

- `gcloud`

For installation, see [this](https://cloud.google.com/sdk/docs/install) page.

Useful commands:

```shell
gcloud init
gcloud auth login
gcloud auth application-default login
```

## Usage

Either edit the `variables.tf` or create a `terraform.tfvars` file in this directory.  
An example of a `terraform.tfvars` file could be:

```hcl
project_name = "myproject"
ansible_windows_hosts = [
    "server01",
    "server02",
    "server03",
    "server04",
    "server05",
    "server06",
    "server07",
    "server08",
    "server09",
    "server10",
    "server11",
    "server12",
    "server13",
    "server14",
    "server15",
  ]
```

Then it's just a case of:

```shell
terraform init
terraform plan
terraform apply
```

At the end of the run, the IP addresses of the VM's are outputted.  
For the Windows hosts, separate text files are created in the root of this directory
which have the formate `password-<server_name>.txt`.

## Author

- Chris van Meer <c.v.meer@atcomputing.nl>
