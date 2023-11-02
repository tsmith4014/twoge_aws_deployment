# Comprehensive AWS Deployment Guide for Twoge Application

This is a comprehensive guide for deploying the Twoge application on AWS. It's designed for users with minimal AWS and networking knowledge. You'll find instructions for setting up the entire infrastructure using the AWS Management Console, as well as terminal commands needed for server setup and software installation.  

---

Embark on a captivating expedition into the deployment cosmos of the Twoge application, powered by AWS's mighty services. This guide not only navigates you through the steps of erecting a robust AWS infrastructure but also showcases our deployment saga through an animated, music-accompanied AWS architecture diagram that’s nothing short of a celestial experience: [Twoge AWS Architecture Odyssey](https://tsmith4014.github.io/twoge_aws_deployment/). 

Imagine a diagram that comes alive, where each service and connection pulsates with the rhythm of animation and music, set against the tranquil vastness of a star-studded digital cosmos. This is an invitation to interact with the very fabric of our cloud setup, to understand its dynamics, and to add your own flare by populating this virtual sky with more stars.

This README is your launchpad. Whether you’re a neophyte to cloud formations or a sage of system administrations, you’ll find your bearings here with straightforward instructions, clear command-line examples, and the thrill of deploying a live application that will soar through the AWS cloud space.

---

## Table of Contents

  - [AWS Reliability and Scalability](#aws-reliability-and-scalability)
  - [Step-by-Step Guide](#step-by-step-guide)
  - [Create Amazon VPC with Two Public subnets](#create-amazon-vpc-with-two-public-subnets)
  - [Create IAM Role for S3](#create-iam-role-for-s3)
  - [Host Static Files in S3 with IAM Policy](#host-static-files-in-s3-with-iam-policy)
  - [Launch EC2 Instance with Amazon Linux 2 AMI AWS RDS and Twoge Configuration](#launch-ec2-instance-with-amazon-linux-2-ami-aws-rds-and-twoge-configuration)
  - [Deploying RDS with PostgreSQL](#deploying-rds-with-postgresql)
  - [Step-By-Step Instruction Guide to Deploy Twoge on an EC2 instance](#step-by-step-instruction-guide-to-deploy-twoge-on-an-ec2-instance)
  - [Create an Image of the Instance](#create-an-image-of-the-instance)
  - [Create a Launch Template Using the Image Created](#create-a-launch-template-using-the-image-created)
  - [Creating a Target Group](#creating-a-target-group)
  - [Create Load Balancers](#create-load-balancers)
  - [Create an Auto Scaling Group](#create-an-auto-scaling-group)
  - [Create an ASG Dynamic Scaling Policy](#create-an-asg-dynamic-scaling-policy)
  - [Appendix](#appendix)

---

## AWS Reliability and Scalability

Embrace the power of AWS's robust cloud infrastructure, ensuring your Twoge application benefits from the foundational principles of high availability and elastic scalability. Utilize multi-AZ deployments to leverage the distributed nature of AWS Availability Zones, each a bastion of stability with its redundant power, networking, and connectivity. This geographical separation ensures that the Twoge application remains resilient in the face of potential disruptions.

Harness the dynamic duo of Elastic Load Balancing (ELB) and Auto Scaling Groups (ASG) to imbue your application with the agility of AWS's elastic computing capabilities. ELB seamlessly spreads incoming traffic across numerous compute resources, ensuring smooth operation under varying load conditions. Concurrently, ASGs work tirelessly to maintain the perfect balance of EC2 instances—scaling in harmony with the ebbs and flows of demand.

These services together construct an environment where Twoge can not only exist but flourish—adjusting resource allocation with precision and maintaining uptime with assured reliability. This is the canvas upon which your application's resilience is painted, making it not just operational but truly optimized for the cloud.


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
4. **Review and Create Role**: Give the role a name,`ec2-twoge-s3`, and click `Create Role`.

---

### Host Static Files in S3 with IAM Policy

1. **Navigate to S3 Dashboard**: Open AWS Console and go to Services > S3.
2. **Create Bucket**: Click `Create bucket`.
   - **Name**: `vega-twoge-static-files`
   - **Uncheck**: `Block all public access`
   - **General Settings**: `ACLs disabled, bucket versionalizing disabled, default encryption disabled`
3. **Bucket Policy**: Once the bucket is created, navigate to `Permissions` tab, and then click on `Bucket Policy`.
   - Copy the JSON policy below and paste it into the editor.

```json
{
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEC2Instance",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": "arn:aws:s3:::vega-twoge-static-files/*",
            "Condition": {
                "StringEquals": {
                    "aws:userid": "arn:aws:iam::182403015120:role/ec2-static-s3-access"
                }
            }
        }
    ]
}
```

4. **Save Policy**: Click `Save`.

5. **Upload Static Files**: Upload the static files to the bucket.

6. **To list the contents of an S3 bucket**, use the `s3 ls` command and verify that the files are present and premission is granted (this must be done from the EC2 instance with the IAM role attached)):

```sh
aws s3 ls s3://vega-twoge-static-files --recursive --human-readable --summarize
```

---

## Launch EC2 Instance with Amazon Linux 2 AMI AWS RDS and Twoge Configuration

1. **Access EC2 Dashboard**: Open AWS Console and go to **Services > EC2**.
2. **Launch Instance**: Click **Launch Instance > Amazon Linux 2 AMI**.
3. **Instance Type**: Give a name, select your key pair, and select an instance type `t2.micro`.
4. **IAM Role**: Select the IAM role created earlier for S3 (`ec2-twoge-s3`).
5. **Security Group**: Configure to allow inbound HTTP/HTTPS and SSH traffic, enabled Auto-assign ip.
6. **Review and Launch**: Review your configurations and click **Launch**.

---

## Deploying RDS with PostgreSQL

This guide walks you through the process of deploying an Amazon RDS instance using PostgreSQL.

### Step 1: Create Database

1. Go to the AWS Management Console.
2. In the **Search Bar**, type `RDS` and select the RDS service.
3. Click **Create database**.

### Step 2: Database Configuration

1. Choose **Standard create**.
2. For **Engine type**, select `PostgreSQL`.
3. For **Engine Version**, choose `15.3-r2`.
4. Under **Templates**, select `Free tier`.

### Step 3: Settings

1. Under **Settings**:
   - **DB instance identifier**: Create and enter the name of your database.
   - **Master username**: It's recommended to change the username.
   - **Master Password**: Enter a personal password and confirm it.

### Step 4: Instance Configuration

- Choose `db.t3.micro` for **Instance configuration**.

### Step 5: Storage

- Leave the default values for **Storage**.
- For **Storage autoscaling**, deselect `Enable Storage autoscaling`.

### Step 6: Connectivity

1. Under **Connectivity**:
   - Choose `Don't connect to an EC2 compute resource`.
   - Select `IPv4`.
   - For **Virtual private cloud**, choose the same VPC selected for your EC2.
   - Leave **DB subnet group** as default.
   - Set **Public Access** to `Yes`.
   - For **VPC security group**, create a new one.
   - Enter a name for your new VPC security group under **New Vpc security group name**.

### Step 7: Additional Configurations

1. Set the **Database port** to `5432`.
2. Under **Database authentication**, select `Password authentication`.

### Step 8: Monitoring

- Leave all values under **Monitoring** as default.

### Step 9: Additional Configuration

1. Under **Additional configuration**:
   - For **Initial database name**, enter the database name associated with your Flask app.

### Step 10: Create Database

- Click **Create Database**. Keep in mind that the initialization of the database will take about 5-10 minutes.

### Step 11: Post-Creation Setup

1. Once the database is created, select it to navigate to the **Connectivity & security** tab.
2. Select the **VPC Security groups**.
3. Click on the security group you created for your database.
4. Click **Edit inbound rules**.

### Step 12: Edit Inbound Rules

Your inbound rules should look like this:

- **Type**: `PostgreSQL`
- **Protocol**: `TCP`
- **Port Range**: `5432`
- **Source**: `Custom`
- **Destination**: Enter the security group of your EC2 instance previously created.

### Conclusion

After setting up the inbound rules, your RDS instance should be ready to connect to your application. Ensure that your EC2 instance's security group allows inbound traffic on port `5432` from the RDS security group.

---

## Step-By-Step Instruction Guide to Deploy Twoge on an EC2 instance

1. **SSH into EC2 instance**

   ```bash
   ssh ec2-user@<Your_EC2_IP>
   ```

2. **Update package manager**

   ```bash
   sudo yum update -y
   ```

3. **Install Git & Amazon-Extras**

   ```bash
   sudo yum install git -y
   sudo amazon-linux-extras install nginx1 -y
   ```

4. **Clone the Twoge repository**

   ```bash
   git clone https://github.com/chandradeoarya/twoge
   ```

5. **Navigate to the cloned repository**

   ```bash
   cd twoge
   ```

6. **Install Python-Pip**

   ```bash
   sudo yum install python3-pip -y
   ```

7. **Create & Activate the virtual environment**

   ```bash
      python3 -m venv venv
   ```

   ```bash
      source venv/bin/activate
   ```

8. **Install Python dependencies**

   ```bash
   pip install -r requirements.txt
   ```

9. **create .env for psql access**

   ```bash
   echo 'SQLALCHEMY_DATABASE_URI = "postgresql://username:password@aws-database/database-name"' > .env
   ```

10. **Create a systemd service file**
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

11. **Move the service file to the systemd directory**

    ```bash
    sudo cp twoge.service /etc/systemd/system/twoge.service
    ```

12. **Reload systemd daemon**

    ```bash
    sudo systemctl daemon-reload
    ```

13. **Enable the service**

    ```bash
    sudo systemctl enable twoge.service
    ```

14. **Start the service**

    ```bash
    sudo systemctl start twoge.service
    ```

15. **Check the service status**

    ```bash
    sudo systemctl status twoge.service
    ```

16. **Navigate to etc/nginx and create the sites-avalable and sites-enabled dirs**

    ```bash
    sudo mkdir sites-available
    sudo mkdir sites-enabled
    ```

17. **Navigate to sites-available and create/add the nginx config named twoge_nginx**

    ```nginx
    server {
       listen 80;
       server_name *;  # underscore as a catch-all

       location / {
          include proxy_params;
          proxy_pass twoge-app-load-balancer-1298083779.eu-west-2.elb.amazonaws.com;
       }
    }

    ```

18. **Link the config file to sites-enabled**

    ```bash

       sudo ln -s /etc/nginx/sites-available/twoge_nginx /etc/nginx/sites-enabled/

    ```

19. **Restart Nginx to apply changes**

    ```bash

      sudo systemctl daemon-reload

    ```

20. **Check Nginx status**

    ```bash

      sudo systemctl restart nginx

    ```

21. **Check Nginx status**

    ```bash

      sudo systemctl status nginx

    ```

---

## Create an Image of the Instance

To create an image of your EC2 instance:

1. Select your instance in the EC2 dashboard.
2. Go to **Actions** > **Image and templates** > **Create Image**.
3. Enter an image name and add a description.
4. Leave all other settings as default.
5. Click **Create Image**.

---

## Create a Launch Template Using the Image Created

To create a launch template:

1. Navigate to **Launch Templates** in the EC2 dashboard.
2. Click **Create launch template**.
3. Provide a name for your template and specify the template version.
4. Under **Application and OS images**, click on **My AMIs**.
5. Select **Owned by me** and choose the image you created earlier.
6. Set the **Instance Type** to `t2.micro`.
7. Choose the key pair that was used when creating the EC2 instance.
8. In **Network Settings**, leave the subnet as default.
9. For **Firewall/Security group**, select the existing security group associated with your EC2 instance.
10. Under **Advanced details**, set the **IAM instance profile** to the role that allows EC2 access to the S3 bucket.
11. Click to create the launch template.

---

## Creating a Target Group

To set up a target group for your instances:

1. Go to **Target Groups** in the EC2 dashboard.
2. Click **Create target group**.
3. Choose **Instances** as the target type.
4. Enter a name for your target group.
5. Set the **Protocol port** to `9876`.
6. Select **IPv4**.
7. Choose the VPC that was used for the EC2 instance.
8. Leave all other settings as default and click **Next**.
9. In **Register targets**, select the EC2 instances you wish to include.
10. Click to include them as pending below.
11. Finally, click **Create target group**.

---

## Create Load Balancers

To set up an Application Load Balancer:

1. Navigate to **Load Balancers** in the EC2 dashboard.
2. Click **Create load balancer** and select **Application Load Balancer**.
3. Enter a name for your Load Balancer.
4. For the VPC, select the same one you chose for your EC2 instance.
5. Under **Mappings**, select the Availability Zones you wish to use.
6. Create a new Security Group (SG) that allows HTTP/HTTPS and a custom TCP rule with port range `9876`.
7. In **Listeners and routing**, select the target group you previously created.
8. Click **Create Load Balancer**.

## Create an Auto Scaling Group

To create an Auto Scaling Group:

1. Go to **Auto Scaling groups** and click **Create Auto Scaling group**.
2. Name your ASG and select the launch template you previously created.
3. Choose the same VPC and Availability Zones as your EC2 instance.
4. Attach the ASG to an existing load balancer by selecting your Load Balancer.
5. Under **Health checks**, enable ELB health checks and set the health check grace period to `120`.
6. Set the group size: Desired (`2`), Minimum (`1`), Maximum (`3`).
7. Skip scaling policies for now.
8. To add notifications, create a new topic, enter a topic name, and add your email as a recipient.
9. Select event types for notifications (`Launch`, `Terminate`) and confirm subscriptions.
10. Proceed through the next steps until you reach **Create ASG** and finalize the creation.

## Create an ASG Dynamic Scaling Policy

To create a dynamic scaling policy for your ASG:

1. Select your ASG and go to **Automatic Scaling** > **Dynamic scaling policies**.
2. Click **Create Dynamic scaling policy**.
3. Choose **Simple Scaling** as the policy type.
4. Name your policy and create a new CloudWatch alarm.
5. For the metric, navigate to EC2 > By ASG and select your ASG.
6. Choose the metric `CPUUtilization`.
7. Set the metric condition to trigger at a specific threshold of CPU utilization (I set it at 50%).
8. Create a notification topic with your email and set the alarm name.
9. Once the CloudWatch alarm is created, return to the Dynamic Scaling Policy setup.
10. Refresh the CloudWatch Alarm list, select your new alarm, and define the scaling action (e.g., add `1` capacity unit).
11. Set the cooldown period (e.g., `60` seconds).
12. Click **Create** to finalize the dynamic scaling policy.

---

## Appendix

### JSON file of S3 bucket policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEC2Instance",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": ["s3:GetObject", "s3:GetObjectVersion"],
      "Resource": "arn:aws:s3:::vega-twoge-static-files/*",
      "Condition": {
        "StringEquals": {
          "aws:userid": "arn:aws:iam::182403015120:role/ec2-static-s3-access"
        }
      }
    }
  ]
}
```

---

### Twoge Daemon Configuration

```.md
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

### Nginx Configuration Sample with static content hosting(did not implement)

```nginx
server {
    listen 80;
    server_name _;  #underscore as a catch-all

    location / {
        include proxy_params;
        proxy_pass http://twoge-app-load-balancer-1298083779.eu-west-2.elb.amazonaws.com;
    }

    location /static/ {
        proxy_set_header Host vega-twoge-static-files.s3.eu-west-2.amazonaws.com;
        proxy_pass http://vega-twoge-static-files.s3.eu-west-2.amazonaws.com;
    }
}
```

---

## AWS CLI Setup and S3 Bucket Access

To list the contents of an S3 bucket via the AWS CLI, you'll need to have the AWS CLI installed and configured with the necessary access credentials. Below is a Markdown-formatted README section that includes the instructions for installing the AWS CLI, configuring it, and listing the contents of an S3 bucket.

This section provides a guide on how to install the AWS CLI, configure it, and list the contents of an S3 bucket.

### Installing the AWS CLI

To interact with AWS services directly from your terminal, you need to install the AWS Command Line Interface (CLI). Follow the instructions for your operating system:

#### For macOS and Linux:

```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Configuring the AWS CLI

Before using the AWS CLI, you need to configure your AWS credentials. You can do this by running:

```sh
aws configure
```

You will be prompted to enter your `AWS Access Key ID`, `AWS Secret Access Key`, and the `region` you're working in. Optionally, you can also set the output format (e.g., `json`, `text`, or `table`).

### Listing Contents of an S3 Bucket

To list the contents of an S3 bucket, use the `s3 ls` command:

```sh
aws s3 ls s3://your-bucket-name --recursive --human-readable --summarize
```

Replace `your-bucket-name` with the actual name of your S3 bucket.

This command lists all objects in the specified bucket, shows the size of each object in a human-readable format, and provides a summary at the end.

---

## Background Music Credits

### Stay Quiet

- **Artist**: Monplaisir
- **License**: CC0/Public Domain
- **Source**: [Free Music Archive](https://freemusicarchive.org)

This track is used under the terms of the CC0/Public Domain. While no attribution is legally required, credit is given to the artist for their work. It is recommended to verify the status of both the composition and the recording, especially for commercial use, as Public Domain laws may vary by country.

---
