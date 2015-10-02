#/bin/sh
echo "Installing pre-build repo"
if [ ! -d /opt/opnfv/nailgun ]; then
  echo "Error - found no repo!"
  exit 1
fi

mkdir -p /var/www/nailgun
mv /opt/opnfv/nailgun/* /var/www/nailgun
if [ $? -ne 0 ]; then
  echo "Error moving repos to their correct location!"
  exit 1
fi
rmdir /opt/opnfv/nailgun
if [ $? -ne 0 ]; then
  echo "Error removing /opt/opnfv/nailgun directory!"
  exit 1
fi
echo "Done installing pre-build repo"
