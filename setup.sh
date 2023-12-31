#!/bin/bash
sudo yum update -y
sudo yum install git -y
git clone  https://github.com/chandradeoarya/twoge
cd twoge
sudo yum install python-pip -y
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo 'SQLALCHEMY_DATABASE_URI = "postgresql://username:pw@region/databasename"' > .env

echo '
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
WantedBy=multi-user.target' > twoge.service

sudo cp twoge.service /etc/systemd/system/twoge.service

sudo systemctl daemon-reload

sudo systemctl enable twoge

sudo systemctl start twoge

sudo systemctl status twoge
