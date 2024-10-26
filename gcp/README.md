# Google Cloud Platform (GCP)

The following instructions only detail how to set up a Ubuntu VM on GCP.
Compared to other potential options, a VM offers a stateful compute solution with a lower cost.
Cloud run function are not good for stateful continuous networking, K8 is more expensive and offers no continuous free offering.
Based on analysis at the time, a micro VM appears to be the best solution for HK Server hosting.

> [!CAUTION]
> The suggested instances (lowest compute), is part of the [free tier](https://cloud.google.com/free/docs/free-cloud-features#free-tier-usage-limits) of google cloud at time of writing.
> Always confirm and see [pricing details](https://cloud.google.com/compute/all-pricing) for more information.

> [!NOTE]
> The commands here are linux centric. Personally I am using WSL2 on windows, adjust accordingly for other OS.

## Prerequisites

1. Set up a google cloud [project](https://developers.google.com/workspace/guides/create-project) to use and enable GCP on your google account.

2. Go to the [GCP console](https://console.cloud.google.com/welcome?hl=en) and select compute engine, you may need to enable the API.

3. Add ssh key to GCP for logging in, must do this before starting the VM

    - Generate a new ssh key with the user name being your google user name. E.g. `ssh-keygen -t rsa -b 4096 -C <google username>`
    - When asked where to save this file, select somewhere in your `.ssh` folder. E.g. `~/.ssh/gcp.pub`
    - Get the local machine public key with `cat ~/.ssh/gcp.pub`
    - First registry your public ssh key with Google Cloud Project, under `compute engine > settings > metadata` which will have [ssh keys tab](https://console.cloud.google.com/compute/metadata)
    - Add the text as SSH key and press Save
    - Make sure that your [firewall rules](https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/list) allow ssh. The [GCP dashboard](https://console.cloud.google.com/home/dashboard) go VPC Network > Firewall. `default-allow-ssh` at the bottom should be present. Note this will allow anyone with a valid ssh key to log in, to restrict this see this [video](https://youtu.be/8QGpHQ2SyG8?si=slrtrDrYEry1Uo3r&t=516).

## Creating a Virtual Machine

There are two methods for creating a VM on GCP provided.
The first is using manually in the web UI, the second is using terraform.
Terraform is the suggested method if you are looking for reproducability.

### Google Cloud Web UI
    
1. Head to [Google Cloud Engine](https://console.cloud.google.com/compute/instances) and select `Create Instance`
2. Hollowknight multiplayer is a pretty cheap server. So we will use a micro instance on E2 for the cheapest cost:
    - VM Basics:
        - Instance Name: `hollowknight-server`
        - Region: `us-central1` (where ever you want)
        - Zone: `any`
        - VM Provisioning: `Standard`
        - No time limit
    - Machine Config:
        - General Purpose > E2
        - Preset: e2-micro (0.25 vCPU and 1GB Memory)
    - OS and Storage
        - Operatorating System: Ubuntu 22.04 x86
        - Storage Size 10Gb
    - Networking
        - Allow HTTP and HTTPS traffic
        - Ephemeral IP is fine, we'll connect to whatever via the domain
        - Select `standard` network teir. Either select an existing or reserve a static IP like `hollowknight-server`
        - Under Network tags add `hk-server`
    - Advanced
        - Add startup script with the contents of `install_docker.sh`

    > If it is planned to connect a domain to this IP it may be beneficial to reserve a [static IP](https://console.cloud.google.com/networking/addresses/list) that can be used between VMs. DNS records take a while to update so having a fixed IP for GoDaddy to point to is useful. However, be aware that Google [charges more](https://cloud.google.com/vpc/network-pricing#ipaddress) for IPs that are static but not in use.

3. Next create a firewall exceptions for both HKMP and HKMW.
Assuming that the default ports are being used, forward `2222` and `3333` on the VM's IP:

    - Navigate to `VPC network > Firewall`
    - Click `Create Firewall Rule`, name it `hollowknight-server` with description `Hollow Knight multiplayer server port`.
    - Set priority to anything, since this is low priority set this to `2000` (lower = higher priority).
    - For network direction select `Ingress`
    - Under `Targets` select `Specified target tags` and enter tag `hk-server`. This needs to match the tag added to the VM's network tags. If you forgot about this, edit the VM's details in the compute engine.
    - For the source filter select `IPv4` and then set the ranges to `0.0.0.0/0` which will allow all IP ranges (be careful, we have no LB).
    - In protocols / ports, select `UDP` and add port `2222` (multiplayer)
    - In protocols / ports, select `TCP` and add port `3333` (itemsync)
    - Click create and you should see this rule appear in the firewall list

    Note that you can watch the network activity of the VM using the [observability window](https://console.cloud.google.com/compute/instances/observability).

### Terraform

Terraform is infra by code.
It is by far the best way to get a reproducable VM up and running as easy as possible.
Additionally, it ensures that everything is torn down correctly once you're done playing.
[Installing terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) is easy on all platforms.

#### Terraform AuthN

Terraform will need to interact with GCP APIs, so we will need to have a valid account for it to use.
For authentication, we will use our personal account since we are running terraform on our local machine. [Reference](https://cloud.google.com/docs/terraform/authentication)

1. Install the [GCP CLI](https://cloud.google.com/sdk/docs/install#linux), test it is installed with `gcloud --help`
2. Authenticate with `gcloud init`
3. To allow terraform to log in, we will need to acquire new user credientials using `gcloud auth application-default login`. Note where the credential JSON file gets saved (e.g. `.../.config/gcloud/application_default_credentials.json`). This JSON will look something like:

    ```json
    {
        "account": "",
        "client_id": "xxx.apps.googleusercontent.com",
        "client_secret": "...",
        "quota_project_id": "your-project-name",
        "refresh_token": "1//...",
        "type": "authorized_user",
        "universe_domain": "googleapis.com"
    }
    ```

> [!NOTE]
> Customize the properties of VM inside the [variables.tf](terraform/variables.tf) or via CLI commands.

#### Create VM and Firewall Rules

1. Navigate to the [terraform folder](terraform) and initize terraform state with `terraform init`
2. Validate the terraform configs with:
    ```bash
    terraform plan \
    var credential_file=<path to credential json>
    ```
3. Apply terraform config using:
    ```bash
    terraform apply  \
    -var credential_file=<path to credential json> \
    -var project=<gcp project name> \
    -var username=<google username>
    ```

> [!NOTE]
> While the VM may be started, the start up script (which installs docker) will take a minute or two to complete.

## Connecting with SSH

Upon start up, the server should show up in the [VM Instances](https://console.cloud.google.com/compute/instances?onCreate=true).

- Get the external IP of the sever from the [VM dashboard](https://console.cloud.google.com/compute/instances)
- Connect to the running VM using `ssh  -i ~/.ssh/gcp <username>@<external ip-address>`
- Once logged in use `id -Gn` to see what you are added to the [docker user group](https://docs.docker.com/engine/install/linux-postinstall/)
    - If you so not see "docker" run `sudo usermod -aG docker $USER`
    - Relog into the VM
- Check docker is installed fine with `docker ps`, which should show no containers running
    - If docker is not installed, the start up script failed. Try running the commands in `install_docker.sh` manually
    - Can view start up script issues in `/var/log/syslog` if you want to debug. The start up could still be running.

## Running Servers

Refer to the respective server Readme for what you want to run under the docker folder.

## Clean Up

### Google Cloud UI

To clean up the VM, simply delete the instance on the [Google Cloud Engine](https://console.cloud.google.com/compute/instances) page.

### Terraform

`terraform destroy`