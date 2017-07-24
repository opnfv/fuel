{% if grains['cpuarch'] == 'aarch64' %}
vgabios:
  pkg.installed
/usr/share/qemu:
  file.directory
/usr/share/qemu/vgabios-stdvga.bin:
  file.symlink:
    - target: "/usr/share/vgabios/vgabios.bin"
{% endif %}
