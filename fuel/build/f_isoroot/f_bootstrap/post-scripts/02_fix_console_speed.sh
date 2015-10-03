#/bin/sh
echo "Changing console speed to 115200 (std is 9600) on bootstrap"
echo "Old settings"
dockerctl shell cobbler cobbler profile report --name bootstrap
echo "Modifying"
dockerctl shell cobbler cobbler profile edit --name bootstrap --kopts "console=tty0 console=ttyS0,115200" --in-place
echo "New settings"
dockerctl shell cobbler cobbler profile report --name bootstrap
echo "Setting console speed to 115200 on ubuntu_1204_x86_64 (std is no serial console)"
echo "Old settings"
dockerctl shell cobbler cobbler profile report --name ubuntu_1204_x86_64
echo "Modifying"
dockerctl shell cobbler cobbler profile edit --name ubuntu_1204_x86_64 --kopts "console=tty0 console=ttyS0,115200" --in-place
echo "New settings"
dockerctl shell cobbler cobbler profile report --name ubuntu_1204_x86_64
