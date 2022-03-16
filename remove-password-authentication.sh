#!/bin/bash
## Turn off PasswordAuthentication in sshd_config
sudo sed '/PasswordAuthentication/ s/ yes$/ no/' /etc/sshd_config
sudo systemctl restart sshd