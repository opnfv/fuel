{% if grains['cpuarch'] == 'aarch64' %}
qemu-efi:
  pkg.installed
{% endif %}
