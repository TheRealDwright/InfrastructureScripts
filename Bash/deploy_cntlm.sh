#!/bin/bash
# This script will install and configure a cntlm proxy on an Ubuntu Workstation.

echo "Type your fully qualifed active directory domain, followed by [ENTER]:"
read domain

echo "Type your active directory username, followed by [ENTER]:"
read user_name

echo "Type your active directory password, followed by [ENTER]:"
read -s user_password

echo "Type your asset tag, followed by [ENTER]:"
read asset_tag

echo "Type the corporate proxy server IP, followed by [ENTER]:"
read proxy_ip

echo "Type the corporate proxy server port, followed by [ENTER]:"
read proxy_port

echo "user name is $user_name"
echo "user password is $user_password"
echo "machine asset tag is $asset_tag"

function proxy_set {

  if [ 'sudo grep 'http_proxy=http://127.0.0.1:3128' /etc/environment' != 'http_proxy=http://127.0.0.1:3128' ]; then
    sudo echo 'http_proxy=http://127.0.0.1:3128' | sudo tee --append /etc/environment
  fi

  if [ 'sudo grep 'HTTP_PROXY=http://127.0.0.1:3128' /etc/environment' != 'HTTP_PROXY=http://127.0.0.1:3128' ]; then
    sudo echo 'HTTP_PROXY=http://127.0.0.1:3128' | sudo tee --append /etc/environment
  fi

  if [ 'sudo grep 'https_proxy=http://127.0.0.1:3128' /etc/environment' != 'https_proxy=http://127.0.0.1:3128' ]; then
    sudo echo 'https_proxy=http://127.0.0.1:3128' | sudo tee --append /etc/environment
  fi

  if [ 'sudo grep 'HTTPS_PROXY=http://127.0.0.1:3128' /etc/environment' != 'HTTPS_PROXY=http://127.0.0.1:3128' ]; then
    sudo echo 'HTTPS_PROXY=http://127.0.0.1:3128' | sudo tee --append /etc/environment
  fi

}

function cntlm_configure {
  echo 'configuring cntlm for the first time'
  sudo sed -i "s/users_username/$user_name/g" /etc/cntlm.conf
  sudo sed -i "s/users_password/$user_password/g" /etc/cntlm.conf
  sudo sed -i "s/corp-uk/$domain/g" /etc/cntlm.conf
  sudo service cntlm start
  touch ~/proxy_configured.txt
  grep -q -F 'the proxy is configured' ~/proxy_configured.txt || echo 'the proxy is configured' >> ~/proxy_configured.txt
  sudo service cntlm restart
}

function cntlm_reconfigure {
  echo 'reconfiguring cntlm due to pre-existing configuration'
  sudo rm -rf /etc/cntlm.conf
  sudo cp cntlm.conf /etc/cntlm.conf
  sudo sed -i "s/testuser/$user_name/g" /etc/cntlm.conf
  sudo sed -i "s/password/$user_password/g" /etc/cntlm.conf
  sudo sed -i "s/corp-uk/$domain/g" /etc/cntlm.conf
  sudo service cntlm restart
}

function set_hostname {
  echo 'changing the hostname'
  touch ~/hostname
  sudo echo $asset_tag | sudo tee --append ~/hostname
  sudo yes | sudo cp -rf ~/hostname /etc/hostname
}

echo 'installing the cntlm client'
sudo http_proxy=http://$user_name:$user_password@$proxy_ip:$proxy_port apt-get update -y
sudo http_proxy=http://$user_name:$user_password@$proxy_ip:$proxy_port apt-get install -y cntlm

echo 'setting the global system proxy environment variables'
proxy_set

echo 'setting the system host name'
set_hostname

if [ ! -f ~/proxy_configured.txt ]; then
  echo 'executing cntlm_configure function'
  cntlm_configure
else
  echo 'executing cntlm_reconfigure function'
  cntlm_reconfigure
fi

sudo reboot
