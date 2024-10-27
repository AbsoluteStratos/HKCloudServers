# Microsoft Azure

The following instructions only detail how to set up a Ubuntu VM on Microsoft Azure.
Similar to other CSPs there are a few other cloud offerings that could be considered, however the stateful nature of a VM and the free tier offering from Azure makes it the best choice at the moment.

> [!CAUTION]
> The suggested instances (lowest compute), is part of the [free tier](https://azure.microsoft.com/en-us/pricing/free-services) that lasts 12 months on Azure.
> Always confirm and see [pricing details](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/windows/) for more information. Setting a [billing alarm](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/cost-mgt-alerts-monitor-usage-spending) is a great way to protect yourself.

> [!NOTE]
> The commands here are linux centric. Personally I am using WSL2 on windows, adjust accordingly for other OS.

## Prerequisites

1. Set up an [Azure account](https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account/). With a root user set up so you can access the Azure [home](https://portal.azure.com/?quickstart=true#home)

2. We will need to log into the created VM's with SSH, so we will need to [generate a SSH key pair](https://learn.microsoft.com/en-us/azure/virtual-machines/ssh-keys-portal) to use with our instance

    - Navigate to [SSH keys](https://portal.azure.com/?quickstart=true#browse/Microsoft.Compute%2FsshPublicKeys) from the Azure home page
    - Create a new SSH key
    - Resource group: Create new > `hk-servers`
    - Region: Pick where close to where want your server
    - Key pair name: hkazure
    - Select RSA > "Review + create" > "Create" > "Download private key and create resource". This should download a `.pem` file
    - On WSL2 its recommended moving this into WSL's `.ssh` folder, run `chmod -R 700 ~/.ssh/hkazure.pem`

## Creating a Virtual Machine

There are two methods for creating a VM on Azure provided.
The first is using manually in the web UI, the second is using terraform.
Terraform is the suggested method if you are looking for reproducability.

### Azure Web UI

1. From your Azure [home](https://portal.azure.com/?quickstart=true#home)

2. Navigate to [Virtual machines](https://portal.azure.com/?quickstart=true#browse/Microsoft.Compute%2FVirtualMachines) and click create "Azure virtual machine"

    - Basis Tab:
        - Resource group: `hk-servers`
        - Virtual machine name: `hollow-knight-server`
        - Region: Pick where you want the servered.
        - Availability options: No infra redundancy required
        - Security type: Standard
        - Image: Unbuntu Server 24.04 LTS (free services eligible)
        - VM architecture: x86
        - Size: `Standard_B1s - 1 vcpu, 1 GiB memory ($9.64/month) (free services eligible)` or `B2ats_v2 (free services eligible)`
            > [!CAUTION]
            > The free tier size may not be avaialble in your prefered region, at time of writing the US had none of the free tier available. If you are hell bent on using Azure, look at other low cost sizes, but you will pay.
        - Authentication type: SSH
        - Username: ubuntu
        - SSH public key source: Existing key in Azure
        - Stored Keys: `hkazure` from [prerequisites](#prerequisites) steps
        - Public inbound ports: Allow select port
        - Select inbound ports: SSH, HTTP, HTTPS
    - Disks Tab:
        - OS disk size: 30 Gb
        - OS dist type: Standard SSD
    - Networking Tab:
        - Virtual network: Should already be prefilled to create a new one `hollow-knight-server-net`
        - Subnet: Use the default 10.0.0.0/24
        - NIC network security group: Advanced
        - Configure network security group: "Create New" with name `hk-security-group`
        - Load balancing options: None
    - Networking Tab:
        - Custom data and cloud init add contents of `terraform/install_docker.sh`

3. Review + Create > Create. After launching, the instance should be visible under the [virtual machine page](https://portal.azure.com/?quickstart=true#browse/Microsoft.Compute%2FVirtualMachines).

4. Navigate to [Network security groups](https://portal.azure.com/?quickstart=true#browse/Microsoft.Network%2FNetworkSecurityGroups) page, select `hk-security-group`

    - Settings > Inbound security rules
    - Add the following Inbound rules (SSH one should be added already)
        | Source | Port | Destination | Service | Port | Protocol | Action | Priority  | Name | Desciption   |
        |--------|------|-------------|---------|------|----------|--------|-----------|------|--------------|
        | Any    | *    | Any         | SSH     | 22   | TCP      | Allow  | 1000      | SSH  | SSH inbound  |
        | Any    | *    | Any         | Custom  | 2222 | UDP      | Allow  | 1010      | HKMP | HKMP inbound |
        | Any    | *    | Any         | Custom  | 3333 | TCP      | Allow  | 1020      | HKMW | HKMW inbound |

### Terraform

Coming Soon ~ Maybe

## Connecting with SSH

Upon start up, the server should show up in the [virtual machine page](https://portal.azure.com/?quickstart=true#home).

- Get the Public IPv4 address of the sever from the VM's instance page
- Assuming you moved the `.pem` file from the [prerequisites](#prerequisites) step to your `.ssh` folder, connect to the running VM using `ssh  -i ~/.ssh/hkazure.pem ubuntu@<external ip-address>`
- Once logged in use `id -Gn` to see what you are added to the [docker user group](https://docs.docker.com/engine/install/linux-postinstall/)
    - If you so not see "docker" run `sudo usermod -aG docker $USER`
    - Relog into the VM
- Check docker is installed fine with `docker ps`, which should show no containers running
    - If docker is not installed, the start up script failed. Try running the commands in `terraform/install_docker.sh` manually
    - Can view start up script issues in `/var/log/cloud-init-output.log` if you want to debug. The start up could still be running.

## Running Servers

Refer to the respective server Readme for what you want to run under the docker folder.

## Clean Up

### Azure Web UI

To clean up the VM, under the general VM page select `hollow-knight-server` and "Delete".
You can also go delete your security group and network as well if you want to be thorough.

### Terraform

`terraform destroy`