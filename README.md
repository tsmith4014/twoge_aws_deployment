## Adding RDS PostgreSQL Section

# Comprehensive AWS Deployment Guide for Twoge Application

This is a comprehensive guide for deploying the Twoge application on AWS. It's designed for users with minimal AWS and networking knowledge. You'll find instructions for setting up the entire infrastructure using the AWS Management Console, as well as terminal commands needed for server setup and software installation.

## Table of Contents

- [Prerequisites](#prerequisites)
- [AWS Services and Their Purpose](#aws-services-and-their-purpose)
- [Step-by-Step Guide](#step-by-step-guide)
  - [Create Amazon VPC with Two Public subnets](#create-amazon-vpc-with-two-public-subnets)
  - [Create IAM Role for S3](#create-iam-role-for-s3)
  - [Host Static Files in S3 with IAM Policy](#host-static-files-in-s3-with-iam-policy)
  - [Launch EC2 Instance with Amazon Linux 2 AMI and Twoge Configuration](#launch-ec2-instance-with-amazon-linux-2-ami-and-twoge-configuration)
    - [SSH into EC2 and Install Twoge](#ssh-into-ec2-and-install-twoge)
    - [Installing Nginx](#installing-nginx)
    - [Nginx Configuration](#nginx-configuration)
  - [Create Amazon RDS for PostgreSQL](#create-amazon-rds-for-postgresql)
  - [Twoge Daemon](#twoge-daemon)
  - [Create Amazon ALB](#create-amazon-alb)
  - [Configure Amazon ASG with ALB](#configure-amazon-asg-with-alb)
  - [Configure Amazon SNS for ASG Notifications](#configure-amazon-sns-for-asg-notifications)
- [Appendix](#appendix)
  - [Terminal Commands](#terminal-commands)
  - [JSON file of S3 bucket policy](#json-file-of-s3-bucket-policy)
  - [Nginx Configuration Sample](#nginx-configuration-sample)
  - [Twoge Daemon Configuration](#twoge-daemon-configuration)

## Step-by-Step Guide

### Create Amazon VPC with Two Public Subnets

1. **Navigate to VPC Dashboard**: Open AWS Console and go to **Services > VPC**.
2. **Create VPC**: Click on **Create VPC**.

   - Choose **VPC and more** to create the VPC along with other networking resources.
   - Name Tag: `vega-twoge-VPC`
   - IPv4 CIDR block: `10.0.0.0/16`
   - Number of public subnets: 2

3. **Create Public Subnets**: Navigate to **Subnets > Create subnet**.

   - Name: `Twoge-PublicSubnet1`
   - VPC: Choose `Twoge-VPC`
   - CIDR block: `10.0.1.0/24`

   Repeat for the second public subnet (`Twoge-PublicSubnet2` and `10.0.2.0/24`).

### Host Static Files in S3

1. **Navigate to S3 Dashboard**: Open AWS Console and go to **Services > S3**.
2. **Create Bucket**: Click **Create bucket**.
   - Name: `twoge-static-files`
   - Uncheck: `Block all public access`

---

### Create IAM Role for S3

1. **Navigate to IAM Dashboard**: Open AWS Console and go to Services > IAM > Roles.
2. **Create Role**: Click `Create role` > `EC2`.
3. **Attach Policies**: Search for `AmazonS3FullAccess` and attach it.
4. **Review and Create Role**: Give the role a name, like `Twoge-S3-Role`, and click `Create Role`.

### Host Static Files in S3 with IAM Policy

1. **Navigate to S3 Dashboard**: Open AWS Console and go to Services > S3.
2. **Create Bucket**: Click `Create bucket`.
   - **Name**: `vega-twoge-static-files`
   - **Uncheck**: `Block all public access`
3. **Bucket Policy**: Once the bucket is created, navigate to `Permissions` tab, and then click on `Bucket Policy`.
   - Copy the JSON policy below and paste it into the editor.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::vega-twoge-static-files/*"]
    }
  ]
}
```

4. **Save Policy**: Click `Save`.

---

## Launch EC2 Instance with Amazon Linux 2 AMI and Twoge Configuration

1. **Access EC2 Dashboard**: Open AWS Console and go to **Services > EC2**.
2. **Launch Instance**: Click **Launch Instance > Amazon Linux 2 AMI**.
3. **Instance Type**: Select an instance type `t2.micro`.
4. **IAM Role**: Select the IAM role created earlier for S3 (`Twoge-S3-Role`).
5. **Security Group**: Configure to allow inbound HTTP/HTTPS and SSH traffic.
6. **Review and Launch**: Review your configurations and click **Launch**.

### SSH into EC2 and Install Twoge

1. **SSH Access**: To SSH into your instance, run:

   ```sh
   ssh -i "YourKeyPair.pem" ec2-user@<Public-IP-Address>
   ```

2. **Update Packages**:

   ```sh
   sudo yum update -y
   ```

3. **Twoge Setup**: Chandra's Twoge setup script, upload it to the EC2 instance using `scp` and run it:

   ```sh
   chmod +x chandra-twoge-setup.sh
   ./chandra-twoge-setup.sh
   ```

#### Installing Nginx

After SSH access, install Nginx:

```sh
sudo yum update -y
sudo amazon-linux-extras install nginx1.12 -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### Nginx Configuration

Open the Nginx configuration file:

```sh
sudo nano /etc/nginx/nginx.conf
```

Save and restart Nginx:

```sh
sudo systemctl restart nginx
```

### Create Amazon RDS for PostgreSQL

1. **Navigate to RDS Dashboard**: Open the AWS Console and go to **Services > RDS**.
2. **Create Database**: Click on **Create Database** and select **PostgreSQL** as your database engine.
3. **Specifications**:
   - Instance class: Select according to your needs.
   - Multi-AZ Deployment: Enable for higher availability.
   - Storage: Choose the type and size as needed.
4. **Settings**:
   - DB Instance Identifier: `twoge-database`
   - Master Username: `[Your-Username]`
   - Master Password: `[Your-Password]`
5. **Connectivity**:
   - VPC: Select the VPC you created earlier.
   - Subnet Group: Create a new DB Subnet Group or select an existing one.
   - Public Access: Choose according to your needs.
6. **Database Options**:
   - Initial DB name: `twoge_db`
   - Port: `5432`
7. **Backups and Monitoring**: Configure backup and monitoring settings according to your needs.
8. **Launch Database**: Review your configurations and click **Create Database**.

Your PostgreSQL database should now be ready for use. You can connect to it using the `psql` utility from your EC2 instance:

```sh
psql -h [DB-Endpoint] -U [Your-Username] -d [Database-Name]
```

Enter the password when prompted.

### Twoge Daemon

Create a systemd service file:

```sh
sudo nano /etc/systemd/system/twoge.service
```

Enable and start the service:

```sh
sudo systemctl enable twoge.service
sudo systemctl start twoge.service
```

---

## Create and Configure Amazon ALB

1. **Navigate to ALB Dashboard**: Open AWS Console and go to **Services > EC2 > Load Balancers**.
2. **Create ALB**: Click **Create Load Balancer > Application Load Balancer**.
3. **Name and Scheme**: Provide a name and choose the scheme (typically `internet-facing`).
4. **Listeners**: Keep the default HTTP listener.
5. **Target Group**: Create a new target group and select your EC2 instance as the target.
6. **Review and Create**: Confirm your settings and create the ALB.

### Add Listener Rule

1. **Listener Tab**: Go to the **Listeners** tab in your ALB dashboard.
2. **Add Rule**: Click **Add rule > Forward to** and select your target group.

---

## Configure Amazon ASG with ALB

1. **Navigate to ASG Dashboard**: Open AWS Console and go to **Services > EC2 > Auto Scaling Groups**.
2. **Create ASG**: Click **Create Auto Scaling group**.
3. **Launch Template**: Use the same configurations as your EC2 instance.
4. **Attach to ALB**: In the advanced configurations, attach it to the ALB you created earlier.
5. **Scaling Policy**: Set up a scaling policy based on CPU utilization or other metrics.
6. **Create ASG**: Confirm your settings and create the ASG.

---

## Configure Amazon SNS for ASG Notifications

1. **Navigate to SNS Dashboard**: Open AWS Console and go to **Services > SNS**.
2. **Create Topic**: Click **Create topic** and provide a name.
3. **Add Subscription**: Add a subscription with the protocol as `Email` and endpoint as your email address.
4. **Attach to ASG**: Go back to your ASG settings, find the **Notifications** tab and attach the SNS topic.

---

## Appendix

### Terminal Commands

- **SSH into EC2 instance**

  ```sh
  ssh -i "YourKeyPair.pem" ec2-user@<Public-IP-Address>
  ```

- **Check Nginx status**

  ```sh
  sudo systemctl status nginx
  ```

- **Check Twoge application status**

  ```sh
  sudo systemctl status twoge.service
  ```

### JSON file of S3 bucket policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::vega-twoge-static-files/*"]
    }
  ]
}
```

### Nginx Configuration Sample

```nginx
server {
    listen       80;
    server_name  localhost;

    location

 / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    location /static/ {
        alias /path/to/static/files/;
    }
}
```

### Twoge Daemon Configuration

```ini
[Unit]
Description=Twoge Daemon

[Service]
ExecStart=/path/to/twoge/app

[Install]
WantedBy=multi-user.target
```
