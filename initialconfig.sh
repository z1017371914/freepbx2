#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo -i
sudo -E apt-get -y install mysql-server
sudo apt-get install openssh-server mysql-client