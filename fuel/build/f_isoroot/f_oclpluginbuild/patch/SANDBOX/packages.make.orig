# -*- mode: makefile -*-
#
# This Makefile is copied by repo to the top of the sandbox
#

include tools/packages/versions.mk

#
# KVERS
#    The kernel version to use when building a kernel module.
KVERS ?= `uname -r`

#
# KEYID
#    Specify secret key id when generating source packages.
#
KEYID?=
KEYOPT=-k$(KEYID)

#
# Directories listed in manifest (excluding package scripts)
#
SOURCE_CONTRAIL_DIRS:=$(shell xmllint --xpath '//manifest/project/@path' .repo/manifest.xml | sed -r 's/path=\"([^\"]+)\"/\1/g' | sed 's/tools\/packages//')
SOURCE_CONTRAIL_ARCHIVE:=SConstruct $(SOURCE_CONTRAIL_DIRS)
SERIES=$(shell lsb_release -c -s)

# DPDK vRouter is currently supported only on Ubuntu 12.04 Precise
ifeq ($(SERIES),precise)
    CONTRAIL_VROUTER_DPDK := contrail-vrouter-dpdk
endif

source-all: source-package-contrail \
        source-package-contrail-web-core \
        source-package-contrail-web-controller

all: package-contrail \
     package-ifmap-server \
     package-ifmap-python-client \
     $(CONTRAIL_VROUTER_DPDK)

package-ifmap-server: clean-ifmap-server debian-ifmap-server
	$(eval PACKAGE := $(patsubst package-%,%,$@))
	@echo "Building package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); fakeroot debian/rules get-orig-source)
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

package-ifmap-python-client: clean-ifmap-python-client debian-ifmap-python-client
	$(eval PACKAGE := $(patsubst package-%,%,$@))
	@echo "Building package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); fakeroot debian/rules get-orig-source)
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

package-contrail-webui-bundle: clean-contrail-webui-bundle debian-contrail-webui-bundle
	$(eval PACKAGE := $(patsubst package-%,%,$@))
	@echo "Building package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); fakeroot debian/rules get-orig-source)
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

package-contrail-web-core: clean-contrail-web-core debian-contrail-web-core
	$(eval PACKAGE := $(patsubst package-%,%,$@))
	@echo "Building package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); sed -i 's/VERSION/$(CONTRAIL_VERSION)/g' debian/changelog)
	(cd build/packages/$(PACKAGE); make -f debian/rules get-orig-source)
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

source-package-contrail-web-core: clean-contrail-web-core debian-contrail-web-core
	$(eval PACKAGE := $(patsubst source-package-%,%,$@))
	@echo "Building source package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); sed -i 's/VERSION/$(CONTRAIL_VERSION)/g' debian/changelog)
	(cd build/packages/$(PACKAGE); sed -i 's/SERIES/$(SERIES)/g' debian/changelog)
	(cd build/packages/$(PACKAGE); make -f debian/rules get-orig-source)
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -S -rfakeroot $(KEYOPT))

package-contrail-web-controller: clean-contrail-web-controller debian-contrail-web-controller
	$(eval PACKAGE := $(patsubst package-%,%,$@))
	@echo "Building package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); sed -i 's/VERSION/$(CONTRAIL_VERSION)/g' debian/changelog)
	(cd build/packages/$(PACKAGE); make -f debian/rules get-orig-source)
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

source-package-contrail-web-controller: clean-contrail-web-controller debian-contrail-web-controller
	$(eval PACKAGE := $(patsubst source-package-%,%,$@))
	@echo "Building source package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); sed -i 's/VERSION/$(CONTRAIL_VERSION)/g' debian/changelog)
	(cd build/packages/$(PACKAGE); sed -i 's/SERIES/$(SERIES)/g' debian/changelog)
	(cd build/packages/$(PACKAGE); make -f debian/rules get-orig-source)
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -S -rfakeroot $(KEYOPT))

package-contrail: debian-contrail
	$(eval PACKAGE := contrail)
	@echo "Building package $(PACKAGE)"
	sed -i 's/VERSION/$(CONTRAIL_VERSION)/g' build/packages/$(PACKAGE)/debian/changelog
	sed -i 's/SERIES/$(SERIES)/g' build/packages/$(PACKAGE)/debian/changelog
	(cd build/packages/$(PACKAGE)/debian; sed -i '/BUILDDEP_SERIES/r builddep.$(SERIES)' control)
	sed -i '/BUILDDEP_SERIES/d' build/packages/$(PACKAGE)/debian/control
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)
	chmod u+x build/packages/contrail/debian/rules.modules
	(cd build/packages/$(PACKAGE); fakeroot debian/rules.modules KVERS=$(KVERS) binary-modules)

source-package-contrail: clean-contrail debian-contrail
	$(eval PACKAGE := contrail)
	sed -i 's/VERSION/$(CONTRAIL_VERSION)/g' build/packages/$(PACKAGE)/debian/changelog
	sed -i 's/SERIES/$(SERIES)/g' build/packages/$(PACKAGE)/debian/changelog
	(cd build/packages/$(PACKAGE)/debian; sed -i '/BUILDDEP_SERIES/r builddep.$(SERIES)' control)
	sed -i '/BUILDDEP_SERIES/d' build/packages/$(PACKAGE)/debian/control
	(cd vrouter; git clean -f -d)
	tar zcf build/packages/contrail_$(CONTRAIL_VERSION).orig.tar.gz $(SOURCE_CONTRAIL_ARCHIVE)
	@echo "Building source package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -S -rfakeroot $(KEYOPT))

source-ifmap-server:
	$(eval PACKAGE := ifmap-server)
	(cd build/packages/$(PACKAGE); fakeroot debian/rules get-orig-source)

source-package-ifmap-server: clean-ifmap-server debian-ifmap-server source-ifmap-server
	$(eval PACKAGE := ifmap-server)
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -S -rfakeroot $(KEYOPT))

package-neutron-plugin-contrail: debian-neutron-plugin-contrail
	$(eval PACKAGE = neutron-plugin-contrail)
	cp -R openstack/neutron_plugin/* build/packages/neutron-plugin-contrail
	sed -i 's/VERSION/$(NEUTRON_VERSION)/g' build/packages/$(PACKAGE)/debian/changelog
	sed -i 's/SERIES/$(SERIES)/g' build/packages/$(PACKAGE)/debian/changelog
	@echo "Building package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

source-package-neutron-plugin-contrail: clean-neutron-plugin-contrail debian-neutron-plugin-contrail source-neutron-plugin-contrail
	$(eval PACKAGE = neutron-plugin-contrail)
	cp -R openstack/neutron_plugin/* build/packages/neutron-plugin-contrail
	sed -i 's/VERSION/$(NEUTRON_VERSION)/g' build/packages/$(PACKAGE)/debian/changelog
	sed -i 's/SERIES/$(SERIES)/g' build/packages/$(PACKAGE)/debian/changelog
	@echo "Building source package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -S -rfakeroot $(KEYOPT))

source-neutron-plugin-contrail: build/packages/neutron-plugin-contrail_$(NEUTRON_VERSION).orig.tar.gz
build/packages/neutron-plugin-contrail_$(NEUTRON_VERSION).orig.tar.gz:
	(cd openstack/neutron_plugin && tar zcvf ../../build/packages/neutron-plugin-contrail_$(NEUTRON_VERSION).orig.tar.gz .)

package-ceilometer-plugin-contrail: debian-ceilometer-plugin-contrail
	$(eval PACKAGE = ceilometer-plugin-contrail)
	cp -R openstack/ceilometer_plugin/* build/packages/ceilometer-plugin-contrail
	sed -i 's/VERSION/$(CEILOMETER_VERSION)/g' build/packages/$(PACKAGE)/debian/changelog
	sed -i 's/SERIES/$(SERIES)/g' build/packages/$(PACKAGE)/debian/changelog
	@echo "Building package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

source-package-ceilometer-plugin-contrail: clean-ceilometer-plugin-contrail debian-ceilometer-plugin-contrail source-ceilometer-plugin-contrail
	$(eval PACKAGE = ceilometer-plugin-contrail)
	cp -R openstack/ceilometer_plugin/* build/packages/ceilometer-plugin-contrail
	sed -i 's/VERSION/$(CEILOMETER_VERSION)/g' build/packages/$(PACKAGE)/debian/changelog
	sed -i 's/SERIES/$(SERIES)/g' build/packages/$(PACKAGE)/debian/changelog
	@echo "Building source package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -S -rfakeroot $(KEYOPT))

source-ceilometer-plugin-contrail: build/packages/ceilometer-plugin-contrail_$(CEILOMETER_VERSION).orig.tar.gz
build/packages/ceilometer-plugin-contrail_$(CEILOMETER_VERSION).orig.tar.gz:
	(cd openstack/ceilometer_plugin && tar zcvf ../../build/packages/ceilometer-plugin-contrail_$(CEILOMETER_VERSION).orig.tar.gz .)

package-contrail-heat: debian-contrail-heat
	$(eval PACKAGE = contrail-heat)
	cp -R openstack/contrail-heat/* build/packages/contrail-heat
	sed -i 's/VERSION/$(CONTRAIL_HEAT_VERSION)/g' build/packages/$(PACKAGE)/debian/changelog
	sed -i 's/SERIES/$(SERIES)/g' build/packages/$(PACKAGE)/debian/changelog
	@echo "Building package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

source-package-contrail-heat: clean-contrail-heat debian-contrail-heat source-contrail-heat
	$(eval PACKAGE = contrail-heat)
	cp -R openstack/contrail-heat/* build/packages/contrail-heat
	sed -i 's/VERSION/$(CONTRAIL_HEAT_VERSION)/g' build/packages/$(PACKAGE)/debian/changelog
	sed -i 's/SERIES/$(SERIES)/g' build/packages/$(PACKAGE)/debian/changelog
	@echo "Building source package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -S -rfakeroot $(KEYOPT))

source-contrail-heat: build/packages/contrail-heat_$(CONTRAIL_HEAT_VERSION).orig.tar.gz
build/packages/contrail-heat_$(CONTRAIL_HEAT_VERSION).orig.tar.gz:
	(cd openstack/contrail-heat && tar zcvf ../../build/packages/contrail-heat_$(CONTRAIL_HEAT_VERSION).orig.tar.gz .)

package-contrail-vrouter-dpdk: debian-contrail-vrouter-dpdk
	$(eval PACKAGE := contrail-vrouter-dpdk)
	@echo "Building package $(PACKAGE)"
	sed -i 's/VERSION/$(CONTRAIL_VERSION)/g' build/packages/$(PACKAGE)/debian/changelog
	sed -i 's/SERIES/$(SERIES)/g' build/packages/$(PACKAGE)/debian/changelog
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

package-%: debian-%
	$(eval PACKAGE := $(patsubst package-%,%,$@))
	@echo "Building package $(PACKAGE)"
	(cd build/packages/$(PACKAGE); dpkg-buildpackage -uc -us -b -rfakeroot)

debian-%:
	$(eval PACKAGE := $(patsubst debian-%,%,$@))
	mkdir -p build/packages/$(PACKAGE)
	cp -R tools/packages/debian/$(PACKAGE)/debian build/packages/$(PACKAGE)
	chmod u+x build/packages/$(PACKAGE)/debian/rules

clean-%:
	$(eval PACKAGE := $(patsubst clean-%,%,$@))
	rm -rf build/packages/$(PACKAGE)
