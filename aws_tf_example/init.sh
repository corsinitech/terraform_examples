#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo service apache2 start
sudo bash -c 'echo Hello, world > /var/www/html/index.html'
sudo service apache2 restart


