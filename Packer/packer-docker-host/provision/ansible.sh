
#!/usr/bin/env bash
sudo apt-get update -y
sudo apt-get install -y software-properties-common git
sudo add-apt-repository -y ppa:ansible/ansible
sudo apt-get update -y
sudo apt-get install -y ansible
sudo apt-get install -y awscli
sudo apt-get -y install -y python-setuptools
sudo mkdir aws-cfn-bootstrap-latest
sudo curl https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz | sudo tar xz -C aws-cfn-bootstrap-latest --strip-components 1
sudo easy_install aws-cfn-bootstrap-latest
sudo cp aws-cfn-bootstrap-latest/bin/cfn-hup /usr/bin/
sudo chmod u+x /usr/bin/cfn*
