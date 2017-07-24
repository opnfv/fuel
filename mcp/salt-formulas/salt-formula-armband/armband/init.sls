include:
 - armband.qemu_efi
 - armband.vgabios
 {%- if salt['pkg.version']('python-nova') %}
 - armband.nova_libvirt
 - armband.nova_config
 {%- endif %}
