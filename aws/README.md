# Amazon Web Services (AWS)

The following instructions only detail how to set up a Ubuntu VM on AWS EC2.
EC2 seems to be the best option right now on AWS from my knowledge at the time of writing with a 12 month free tier program.

> [!CAUTION]
> The suggested instances (lowest compute), is part of the [free tier](https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=*all) that lasts 12 months on AWS.
> Always confirm and see [pricing details](https://aws.amazon.com/ec2/pricing/on-demand/) for more information. Setting a [billing alarm](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html) at 10.00 is a great way to protect yourself.

> [!NOTE]
> The commands here are linux centric. Personally I am using WSL2 on windows, adjust accordingly for other OS.

## Prerequisites

1. Set up an [AWS account](https://aws.amazon.com/resources/create-account/) with a root user set up so you can access the AWS [console](https://us-east-1.console.aws.amazon.com/console/home)

2. We will need to log into the created VM's with SSH, so we will need to [generate a SSH key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) to use with our instance

    - Navigate to EC2 from the AWS console
    - One the left go `Network & Security > Key Pairs` and create a key pair
    - Name it `hkaws`, select RSA and `.pem`
    - Create key pair, which will download a `.pem` file to your machine.
    - On WSL2 its recommended moving this into WSL's `.ssh` folder, run `chmod -R 700 ~/.ssh/hkaws.pem`
    - If you wish to use another SSH client like PuTTY, the [instructions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-linux-inst-from-windows.html) follow a similar process

## Creating a Virtual Machine

There are two methods for creating a VM on AWS provided.
The first is using manually in the web UI, the second is using terraform.
Terraform is the suggested method if you are looking for reproducability.

### AWS Web UI

1. Head to your [AWS Console Home](https://us-east-1.console.aws.amazon.com/console/home) for your prefered region (this tutorial has links for `us-east-1`)

2. Select EC2 to create a new instance (`Services > Compute > EC2`)

3. Create a [security group](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html?icmpid=docs_ec2_console) with firewall rules for the VM to use

    - Navigate to `Network & Security > Security Groups` and Create Security Group
    - Name: `hk-security-group`
    - Description: `Security group for hollow knight servers`
    - VPC: Whatever the default is
    - Add the following Inbound rules
        | Type       | Port Range | Source          | Desciption  |
        |------------|------------|-----------------|-------------|
        | SSH        | 22         | Anywhere - Ipv4 | SSH inbound |
        | Custom UDP | 2222       | Anywhere - Ipv4 | HKMP        |
        | Custom TCP | 3333       | Anywhere - Ipv4 | HKMW        |
    - Outbound rules leave all trafic

3. Under `Instances > Instances`, click the launch instance button
    - Name and tags
        - `hollow-knight-server`
    - Application and OS Images
        - Select Ubuntu 24.04 LTS or Ubuntu 22.04 LTS
        - Architecture x86
    - Instance type
        - Select t2.micro (should be marked "Free tier eligible)
    - Key pair
        - Select your key pair created from above (`hkaws`)
    - Network Settings
        - Under firewall use "Select existing security group"
        - Select `hk-security-group` created from above
    - Configure Storage 
        - 8Gb - gp3
    - Advanced details
        - Add User data with the contents of `terraform/install_docker.sh`
    
    > If it is planned to connect a domain to this IP it may be beneficial to reserve a [static IP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html) that can be used between VMs.DNS records take a while to update so having a fixed IP for GoDaddy to point to is useful. However, be aware that this additional feature will [cost money](https://aws.amazon.com/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/) and is not covered by the free tier, 0.005 USD an hour at time of writing.

4. After launching, the instance should be visible under the [instance page](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:) under EC2.

### Terraform

Terraform is infra by code.
It is by far the best way to get a reproducable VM up and running as easy as possible.
Additionally, it ensures that everything is torn down correctly once you're done playing.
[Installing terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) is easy on all platforms.

#### Terraform AuthN

Terraform will need to interact with AWS APIs to create the VM, thus credentials must be provided to terraform to authenticate with the AWS servers.
Forcunately there are [several](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) fairly simple methods that can be used.
These docs will use the AWS CLI's config file to authenticate, you only need to do this once.

1. First create [new access keys](https://docs.aws.amazon.com/keyspaces/latest/devguide/create.keypair.html) to use
    - Go to [IAM Dashboard](https://us-east-1.console.aws.amazon.com/iam/home#/home) then "Users > Create New User"
        - Name: `aws-ec2-admin-hk`
        - Permissions options: Select "Attach policies directly" and then fine `AmazonEC2FullAccess`
        - Create User
    - Back on the Users page select the `aws-ec2-admin-hk` profile
    - Navigate to "Security Credentials" and under "Access Keys" create a new acess key
        - Use case: Local Code
        - Description: Hollow Knight Terraform
    - Copy the "Access key" and "Secret access key" creditials (and keep them safe)

2. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), test it is installed with `aws --version`
3. Use the AWS CLI to create a config for you using `aws configure --profile hollowknight`
    - AWS Access Key ID: Use the IAM Access key created
    - AWS Secret Access Key: Use the IAM secret access key created
    - Region: Enter in the compute region to use (e.g. `us-east-1`)
    - Ouput Format: json
4. This will create a `~/.aws/config` and `~/.aws/credentials` files that terraform should be able to use.

> You can always use other authentication methods and modify the [providers.tf](terraform/providers.tf) file.

#### Create Infrastructure

1. Navigate to the [terraform folder](terraform) and initize terraform state with `terraform init`
2. Validate the terraform configs with:
    ```bash
    terraform plan
    ```
3. Apply terraform config using:
    ```bash
    terraform apply
    ```
4. If terraform completes successfully, the machines public IP will be printed

> [!NOTE]
> Customize the properties of VM inside the [variables.tf](terraform/variables.tf) or via CLI commands.

## Connecting with SSH

Upon start up, the server should show up in the [EC2 Instances](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:).

- Get the Public IPv4 address of the sever from the [instance dashboard](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:)
- Assuming you moved the `.pem` file from the [prerequisites](#prerequisites) step to your `.ssh` folder, connect to the running VM using `ssh  -i ~/.ssh/hkaws.pem ubuntu@<external ip-address>`
- Once logged in use `id -Gn` to see what you are added to the [docker user group](https://docs.docker.com/engine/install/linux-postinstall/)
    - If you so not see "docker" run `sudo usermod -aG docker $USER`
    - Relog into the VM
- Check docker is installed fine with `docker ps`, which should show no containers running
    - If docker is not installed, the start up script failed. Try running the commands in `terraform/install_docker.sh` manually
    - Can view start up script issues in `/var/log/cloud-init-output.log` if you want to debug. The start up could still be running.

> [!NOTE]
> For some reason the default username on Ubuntu EC2 instances is just `ubuntu`. Do not try to use your AWS username.

## Running Servers

Refer to the respective server Readme for what you want to run under the docker folder.

## Clean Up

### AWS Web UI

To clean up the VM, simply select `Instance State > Terminate Instance` on the [AWS EC2 instances](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:) page.
You can also go delete your security group as well if you want to be thorough.

### Terraform

`terraform destroy`