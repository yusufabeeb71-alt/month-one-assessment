# TechCorp AWS Infrastructure — Month 1 Assessment

## Architecture Overview

```text
Internet
    │
    ▼
Application Load Balancer (public subnets — AZ-a and AZ-b)
    │
    ├──► Web Server 1 (private subnet 1 — AZ-a) t3.micro + Apache
    └──► Web Server 2 (private subnet 2 — AZ-b) t3.micro + Apache

Your Laptop ──SSH──► Bastion Host (public subnet — AZ-a) + Elastic IP
                          │
                          ├──SSH──► Web Server 1  (ssh webuser@10.0.3.x)
                          ├──SSH──► Web Server 2  (ssh webuser@10.0.4.x)
                          └──SSH──► DB Server     (ssh dbuser@10.0.3.x)
                                         │
                                    PostgreSQL 14
                                    (techcorp_db)
```

---

# Resources Created

| Resource         | Name                      | Details                                     |
| ---------------- | ------------------------- | ------------------------------------------- |
| VPC              | techcorp-vpc              | CIDR: 10.0.0.0/16                           |
| Public Subnet 1  | techcorp-public-subnet-1  | CIDR: 10.0.1.0/24 — AZ-a                    |
| Public Subnet 2  | techcorp-public-subnet-2  | CIDR: 10.0.2.0/24 — AZ-b                    |
| Private Subnet 1 | techcorp-private-subnet-1 | CIDR: 10.0.3.0/24 — AZ-a                    |
| Private Subnet 2 | techcorp-private-subnet-2 | CIDR: 10.0.4.0/24 — AZ-b                    |
| Internet Gateway | techcorp-igw              | Attached to VPC                             |
| NAT Gateway 1    | techcorp-nat-1            | In public subnet 1                          |
| NAT Gateway 2    | techcorp-nat-2            | In public subnet 2                          |
| Bastion Host     | techcorp-bastion          | t3.micro — public subnet 1                  |
| Web Server 1     | techcorp-web-1            | t3.micro + Apache — private subnet 1        |
| Web Server 2     | techcorp-web-2            | t3.micro + Apache — private subnet 2        |
| Database Server  | techcorp-db               | t3.small + PostgreSQL 14 — private subnet 1 |
| Load Balancer    | techcorp-alb              | Application — spans both public subnets     |

---

# Security Groups

| Security Group      | Inbound Rules                                                          |
| ------------------- | ---------------------------------------------------------------------- |
| techcorp-bastion-sg | SSH (22) from your IP only                                             |
| techcorp-web-sg     | HTTP (80) and HTTPS (443) from anywhere, SSH (22) from bastion SG only |
| techcorp-db-sg      | PostgreSQL (5432) from web SG only, SSH (22) from bastion SG only      |

---

# Password Security

Passwords are declared as Terraform variables with `sensitive = true` and injected into server scripts at deploy time using `templatefile()`.

* No passwords appear in any `.tf` file or script in this repository
* Passwords only exist in `terraform.tfvars` which is gitignored
* `terraform.tfvars` is never committed to GitHub

---

# File Structure

```text
month-one-assessment/
├── .gitignore
├── README.md
├── main.tf                     # All AWS resource definitions
├── variables.tf                # Variable declarations
├── outputs.tf                  # Output definitions
├── terraform.tfvars            # Your real values — gitignored, never committed
├── terraform.tfvars.example    # Safe example values for reference
├── user_data/
│   ├── web_server_setup.sh     # Installs Apache, creates webuser
│   └── db_server_setup.sh      # Installs PostgreSQL, creates dbuser
└── evidence/
```

---

# Prerequisites

Before deploying, ensure the following tools are installed and configured on your local machine.

## 1. AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

Configure AWS credentials:

```bash
aws configure
```

Example:

```text
AWS Access Key ID: your key
AWS Secret Access Key: your secret
Default region: eu-west-1
Default output format: json
```

Verify the configuration:

```bash
aws sts get-caller-identity
```

---

## 2. Terraform

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor \
  -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform -y
terraform --version
```

---

## 3. SSH Key Pair

Create a key pair in the AWS Console:

```text
AWS Console → EC2 → Key Pairs → Create key pair
```

Settings:

* Name: `techcorp-key`
* Type: RSA
* Format: `.pem`

Move and secure the downloaded key:

```bash
mv ~/Downloads/techcorp-key.pem ~/.ssh/
chmod 400 ~/.ssh/techcorp-key.pem
```

---

# Deployment

## 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/month-one-assessment.git
cd month-one-assessment
```

---

## 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Fill in your values:

```hcl
region            = "eu-west-1"
instance_type_web = "t3.micro"
instance_type_db  = "t3.small"
key_pair_name     = "techcorp-key"
my_ip             = "YOUR_IP_HERE/32"
web_password      = "YourWebPassword123!"
db_password       = "YourDbPassword123!"
```

Get your current public IP:

```bash
curl ifconfig.me
```

Example:

```text
105.112.34.56/32
```

---

## 3. Initialise Terraform

```bash
terraform init
```

---

## 4. Preview the Deployment

```bash
terraform plan
```

You should see approximately 30+ resources to create.

Take a screenshot for your evidence folder.

---

## 5. Deploy Infrastructure

```bash
terraform apply
```

Type:

```text
yes
```

when prompted.

Deployment takes approximately 10 minutes.

Outputs:

```text
load_balancer_dns  = "techcorp-alb-xxxxxxxxx.eu-west-1.elb.amazonaws.com"
bastion_public_ip  = "x.x.x.x"
web_1_private_ip   = "10.0.3.x"
web_2_private_ip   = "10.0.4.x"
db_private_ip      = "10.0.3.x"
```

---

## 6. Wait for Server Initialisation

After deployment completes, wait about 5 minutes for all user data scripts to finish running.

---

# Accessing the Infrastructure

## Web Application

Open the ALB DNS output in your browser:

```text
http://techcorp-alb-xxxxxxxxx.eu-west-1.elb.amazonaws.com
```

Refresh several times to confirm traffic alternates between both web servers.

---

## SSH to the Bastion Host

Load your SSH key into the agent:

```bash
eval $(ssh-agent -s)
ssh-add ~/.ssh/techcorp-key.pem
```

Connect:

```bash
ssh -A -i ~/.ssh/techcorp-key.pem ec2-user@<bastion_public_ip>
```

---

## SSH from Bastion to Web Servers

```bash
ssh webuser@<web_1_private_ip>
```

```bash
ssh webuser@<web_2_private_ip>
```

Password:

```text
your web_password value
```

---

## SSH from Bastion to Database Server

```bash
ssh dbuser@<db_private_ip>
```

Password:

```text
your db_password value
```

---

## Connect to PostgreSQL

From inside the database server:

```bash
psql -U techcorp -d techcorp_db -h 127.0.0.1
```

Useful PostgreSQL commands:

```sql
\l
\du
\dt
\q
```

---

# Troubleshooting

## Cannot SSH to Bastion

Your IP address may have changed.

Update `terraform.tfvars`:

```bash
curl ifconfig.me
nano terraform.tfvars
terraform apply
```

---

## Permission Denied When SSHing to Private Servers

Reconnect with SSH agent forwarding enabled:

```bash
exit
eval $(ssh-agent -s)
ssh-add ~/.ssh/techcorp-key.pem

ssh -A -i ~/.ssh/techcorp-key.pem ec2-user@<bastion_public_ip>
```

---

## Web Servers Show 502 Bad Gateway

Apache may not be running.

```bash
sudo systemctl status httpd
sudo systemctl start httpd
sudo systemctl enable httpd
curl http://localhost
```

---

## User Data Script Failed

Sometimes the NAT Gateway is not fully ready when instances boot.

SSH into the server and rerun the setup manually.

---

## Key Pair Not Found Error

Ensure the key pair name matches exactly with the AWS Console.

```bash
nano terraform.tfvars
```

Example:

```hcl
key_pair_name = "exact-name-from-aws-console"
```

Then apply again:

```bash
terraform apply
```

---

# Cleanup

To avoid AWS charges, destroy all infrastructure when finished.

```bash
terraform destroy
```

Type:

```text
yes
```

when prompted.
