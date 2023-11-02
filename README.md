# Comprehensive AWS Deployment Guide for Twoge Application

This is a comprehensive guide for deploying the Twoge application on AWS. It's designed for users with minimal AWS and networking knowledge. You'll find instructions for setting up the entire infrastructure using the AWS Management Console, as well as terminal commands needed for server setup and software installation.

---

## Table of Contents

- [Step-by-Step Guide](#step-by-step-guide)
  - [Create Amazon VPC with Two Public subnets](#create-amazon-vpc-with-two-public-subnets)
  - [Host Static Files in S3 with IAM Policy](#host-static-files-in-s3-with-iam-policy)
  - [Step-By-Step Instruction Guide to Deploy Twoge on an EC2 instance](#step-by-step-instruction-guide-to-deploy-twoge-on-an-ec2-instance)
  - [Create Amazon RDS for PostgreSQL](#create-amazon-rds-for-postgresql)
  - [Twoge Daemon](#twoge-daemon)
  - [Create Amazon ALB](#create-amazon-alb)
  - [Configure Amazon ASG with ALB](#configure-amazon-asg-with-alb)
  - [Configure Amazon SNS for ASG Notifications](#configure-amazon-sns-for-asg-notifications)
  - [Setup Nginx for Reverse Proxy](#setup-nginx-for-reverse-proxy)
  - [Static Content Hosting with ELB and S3](#static-content-hosting-with-elb-and-s3)
- [Appendix](#appendix)
  - [Terminal Commands](#terminal-commands)
  - [JSON file of S3 bucket policy](#json-file-of-s3-bucket-policy)
  - [Twoge Daemon Configuration](#twoge-daemon-configuration)
  - [Nginx Configuration Sample](#nginx-configuration-sample)

---

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

## Step-By-Step Instruction Guide to Deploy Twoge on an EC2 instance

1. **SSH into EC2 instance**

   ```bash
   ssh ec2-user@<Your_EC2_IP>
   ```

2. **Update package manager**

   ```bash
   sudo yum update -y
   ```

3. **Install Git**

   ```bash
   sudo yum install git -y
   ```

4. **Clone the Twoge repository**

   ```bash
   git clone https://github.com/your-github/twoge/
   ```

5. **Navigate to the cloned repository**

   ```bash
   cd twoge
   ```

6. **Install Python-Pip**

   ```bash
   sudo yum install python-pip -y
   ```

7. **Activate the virtual environment**

   ```bash
   source venv/bin/activate
   ```

8. **Install Python dependencies**

   ```bash
   pip install -r requirements.txt
   ```

9. **Create a systemd service file**
   Create a file called `twoge.service` and paste the following content:

   ```
   [Unit]
   Description=Gunicorn instance to serve twoge
   Wants=network.target
   After=syslog.target network-online.target

   [Service]
   Type=simple
   WorkingDirectory=/home/ec2-user/twoge
   Environment="PATH=/home/ec2-user/twoge/venv/bin"
   ExecStart=/home/ec2-user/twoge/venv/bin/gunicorn app:app -c /home/ec2-user/twoge/gunicorn_config.py
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

10. **Move the service file to the systemd directory**

    ```bash
    sudo cp twoge.service /etc/systemd/system
    ```

11. **Reload systemd daemon**

    ```bash
    sudo systemctl daemon-reload
    ```

12. **Enable the service**

    ```bash
    sudo systemctl enable twoge.service
    ```

13. **Start the service**

    ```bash
    sudo systemctl start twoge.service
    ```

14. **Check the service status**

    ```bash
    sudo systemctl status twoge.service
    ```

---

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

### Setup Nginx for Reverse Proxy

1. **SSH into your EC2 instance**

   ```bash
   ssh ec2-user@<Your_EC2_IP>
   ```

2. **Install Nginx**

   ```bash
   sudo amazon-linux-extras install nginx1 -y
   ```

3. **Start Nginx**

   ```bash
   sudo systemctl start nginx
   ```

4. **Enable Nginx to start at boot**

   ```bash
   sudo systemctl enable nginx
   ```

5. **Open Nginx configuration file**

   ```bash
   sudo nano /etc/nginx/nginx.conf
   ```

6. **Modify Nginx configuration**

   Edit the `location / {}` block as follows:

```nginx
server {
   listen 80;
   server_name *;  # It's recommended to use underscore as a catch-all

   location / {
       include proxy_params;
       proxy_pass http://twoge-lb-1073512007.us-east-2.elb.amazonaws.com;
   }

   location /static/ {
       proxy_set_header Host twoge-eval-s3.s3-us-east-2.amazonaws.com;
       proxy_pass http://twoge-eval-s3.s3-us-east-2.amazonaws.com;
   }
}
```

7. **Restart Nginx to apply changes**

   ```bash
   sudo systemctl restart nginx
   ```

---

### Static Content Hosting with ELB and S3

1. **Navigate to S3 Dashboard**: Open AWS Console and go to **Services > S3**.
2. **Create a new bucket for static content**:

   - **Name**: `twoge-static-content`
   - **Uncheck**: `Block all public access`

3. **Bucket Policy**: Attach a policy to make the bucket's content publicly readable.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForGetBucketObjects",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::twoge-static-content/*"
    }
  ]
}
```

4. **Navigate to ALB Dashboard**: Go to **Services > EC2 > Load Balancers**.
5. **Modify Listener Rules**: Add a new rule to route requests for static content to the S3 bucket.

   - **Conditions**: If `Path` is `/static/*`
   - **Actions**: Forward to `twoge-static-content`

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

### Twoge Daemon Configuration

```
[Unit]
Description=Gunicorn instance to serve twoge
Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
WorkingDirectory=/home/ec2-user/twoge
Environment="PATH=/home/ec2-user/twoge/venv/bin"
ExecStart=/home/ec2-user/twoge/venv/bin/gunicorn app:app -c /home/ec2-user/twoge/gunicorn_config.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Nginx Configuration Sample

```nginx
server {
    listen 80;
    server_name _;  # It's recommended to use underscore as a catch-all

    location / {
        include proxy_params;
        proxy_pass http://twoge-lb-1073512007.us-east-2.elb.amazonaws.com;
    }

    location /static/ {
        proxy_set_header Host vega-twoge-static-files.s3.eu-west-2.amazonaws.com;
        proxy_pass http://vega-twoge-static-files.s3.eu-west-2.amazonaws.com;
    }
}
```

## Background Music Credits

### Stay Quiet

- **Artist**: Monplaisir
- **License**: CC0/Public Domain
- **Source**: [Free Music Archive](https://freemusicarchive.org)

This track is used under the terms of the CC0/Public Domain. While no attribution is legally required, credit is given to the artist for their work. It is recommended to verify the status of both the composition and the recording, especially for commercial use, as Public Domain laws may vary by country.
