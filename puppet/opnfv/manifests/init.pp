class opnfv {
    # cent rpms don't setup selinux
    # correctly for ovs to set odl as
    # its manager. disabling it till
    # that's fixed.
    exec {'disable selinux':
        command => '/usr/sbin/setenforce 0',
        unless => '/usr/sbin/getenforce | grep Permissive',
    }
}
