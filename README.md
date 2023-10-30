# Twoge AWS Deployment Guide

This guide outlines the steps to deploy the Twoge application on Amazon Web Services (AWS). We'll be utilizing multiple AWS services to ensure a scalable, reliable, and secure environment for the application.

## Table of Contents

- [Milestone 1: Create Amazon VPC with Two Public Subnets](#milestone-1-create-amazon-vpc-with-two-public-subnets)
- [Milestone 2: Host Static Files in S3](#milestone-2-host-static-files-in-s3)
- [Milestone 3: Create IAM Role](#milestone-3-create-iam-role)
- [Milestone 4: Launch EC2 Instance](#milestone-4-launch-ec2-instance)
- [Milestone 4A: Connect S3 Bucket to EC2](#milestone-4a-connect-s3-bucket-to-ec2)
- [Milestone 5: Create Amazon ALB](#milestone-5-create-amazon-alb)
- [Milestone 6: Create Amazon ASG](#milestone-6-create-amazon-asg)
- [Milestone 7: Use Amazon SNS](#milestone-7-use-amazon-sns)

## Milestone 1: Create Amazon VPC with Two Public Subnets

### Steps:

1. **Navigate to VPC Dashboard**: Open the AWS Console and go to Services -> VPC.
2. **Create VPC**: Click on "Your VPCs" -> "Create VPC", then enter a Name and a CIDR block, for example, `10.0.0.0/16`.
3. **Create Subnets**: Navigate to "Subnets" -> "Create subnet". Choose your VPC, enter a Name, and a CIDR block, for example, `10.0.1.0/24`. Repeat for the second subnet.
4. **Create Internet Gateway**: Go to "Internet Gateways" -> "Create internet gateway", then give it a Name.
5. **Attach Internet Gateway to VPC**: Select your Internet Gateway, go to "Actions" -> "Attach to VPC", and choose your VPC.
6. **Update Route Table**: Go to "Route Tables" -> Select your VPC's route table -> "Routes" -> "Edit routes", then add a new route `0.0.0.0/0` and set its target to your Internet Gateway.

## Milestone 2: Host Static Files in S3

### Steps:

1. **Navigate to S3 Dashboard**: Open the AWS Console and go to Services -> S3.
2. **Create Bucket**: Click "Create bucket", then follow the wizard.
3. **Upload Files**: Navigate to the newly created bucket -> "Upload" -> Drag and drop or use the "Add files" button to upload your static files.

## Milestone 3: Create IAM Role

### Steps:

1. **Navigate to IAM Dashboard**: Open the AWS Console and go to Services -> IAM.
2. **Create Role**: Navigate to "Roles" -> "Create role" -> Choose "EC2" -> Attach the `AmazonS3ReadOnlyAccess` policy -> Review and "Create role".

## Milestone 4: Launch EC2 Instance

### Steps:

1. **Navigate to EC2 Dashboard**: Open the AWS Console and go to Services -> EC2.
2. **Launch Instance**: Click "Launch Instance" -> Choose "Amazon Linux 2 AMI" -> Select your instance type -> On "Configure Instance", select the IAM role you created -> Review and launch the instance.

## Milestone 4A: Connect S3 Bucket to EC2

### Steps:

1. **SSH into EC2**: Use SSH to connect to your EC2 instance.
2. **Install AWS CLI**: Run `sudo yum install aws-cli -y` on your Amazon Linux 2 instance.
3. **Configure AWS CLI**: Run `aws configure`.
4. **Sync S3 Bucket**: Run `aws s3 sync s3://your-s3-bucket-name your-destination-directory`.
5. **Update Twoge Configuration**: Point the Twoge application to the directory where you've synced your S3 files.

## Milestone 5: Create Amazon ALB

### Steps:

1. **Navigate to EC2 Dashboard**: Open the AWS Console and go to Services -> EC2 -> Load Balancers.
2. **Create Load Balancer**: Click "Create Load Balancer" -> Choose "Application Load Balancer" -> Name your ALB and choose your VPC and the public subnets -> Configure security settings -> Configure routing and create a new target group -> Register your EC2 instances -> Review and "Create".

## Milestone 6: Create Amazon ASG

### Steps:

1. **Navigate to EC2 Dashboard**: Open the AWS Console and go to Services -> EC2 -> Auto Scaling -> Auto Scaling Groups.
2. **Create Auto Scaling Group**: Click "Create Auto Scaling group" -> Choose "Launch Configuration" or use an existing one -> Configure settings and attach to your VPC's subnets -> Under Load balancing, select your ALB -> "Create Auto Scaling group".

## Milestone 7: Use Amazon SNS

### Steps:

1. **Navigate to SNS Dashboard**: Open the AWS Console and go to Services -> SNS.
2. **Create Topic**: Click "Create topic" -> Enter a name and display name -> "Create topic".
3. **Create Subscription**: Click "Create subscription" -> Choose "Email" as the protocol and enter your email address.
4. **Attach to ASG**: Go back to EC2

-> Auto Scaling Groups -> select your ASG -> "Edit" -> Scroll down to "Notifications" -> "Add notification" -> Choose the SNS topic you created.

By following these milestones, you will set up a robust AWS infrastructure for the Twoge application. This setup ensures scalability, reliability, and fault-tolerance.
