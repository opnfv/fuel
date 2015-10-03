#/bin/sh
echo "Setting intel_iommu=off in bootstrap profile - a fix for the Dell systems"
echo "Old settings"
dockerctl shell cobbler cobbler profile report --name bootstrap
echo "Modifying"
dockerctl shell cobbler cobbler profile edit --name bootstrap --kopts "intel_iommu=off" --in-place
echo "New settings"
dockerctl shell cobbler cobbler profile report --name bootstrap

