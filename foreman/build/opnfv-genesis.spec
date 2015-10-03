Name:		opnfv-genesis
Version:	0.2
Release:	1
Summary:	The files from the OPNFV genesis repo

Group:		System Environment
License:	Apache 2.0
URL:		https://gerrit.opnfv.org/gerrit/genesis.git
Source0:	opnfv-genesis.tar.gz

#BuildRequires:
Requires:	vagrant, VirtualBox-4.3, net-tools

%description
The files from the OPNFV genesis repo

%prep
%setup -q


%build

%install
mkdir -p %{buildroot}/root/genesis
cp -r foreman/ %{buildroot}/root/genesis
cp -r common/ %{buildroot}/root/genesis

%files
/root/genesis


%changelog
* Tue Sep 15 2015 Dan Radez <dradez@redhat.com> - 0.2-1
- Updating the install files and cleaning up white space
* Fri Apr 24 2015 Dan Radez <dradez@redhat.com> - 0.1-1
- Initial Packaging
