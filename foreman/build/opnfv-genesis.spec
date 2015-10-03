Name:		opnfv-genesis
Version:	0.1
Release:	1
Summary:	The files from the OPNFV genesis repo

Group:		System Environment
License:	Apache 2.0
URL:		https://gerrit.opnfv.org/gerrit/genesis.git
Source0:	opnfv-genesis.tar.gz

#BuildRequires:	
Requires:	vagrant, VirtualBox-4.3

%description
The files from the OPNFV genesis repo

%prep
%setup -q


%build

%install
mkdir -p %{buildroot}/usr/bin/
cp foreman/ci/deploy.sh %{buildroot}/usr/bin/

%files
/usr/bin/deploy.sh


%changelog
* Fri Apr 24 2015 Dan Radez <dradez@redhatcom> - 0.1-1
- Initial Packaging
