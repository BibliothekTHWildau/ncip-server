#/bin/bash
cd /kohadevbox/ncip-server/
sudo cpanm --installdeps .
sudo cp init-script-template-ktd /etc/init.d/ncip-server
sudo update-rc.d ncip-server defaults
echo "run sudo /etc/init.d/ncip-server start"