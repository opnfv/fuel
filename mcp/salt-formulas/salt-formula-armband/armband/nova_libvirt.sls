{% if grains['cpuarch'] == 'aarch64' %}
nova-libvirt-aarch64-rollup:
  file.patch:
  - name: /usr/lib/python2.7/dist-packages
  - source: salt://armband/files/nova-libvirt-aarch64-rollup.diff
  - hash: False
  - options: '-p1'
  - unless: 'test -f /var/cache/salt/minion/files/base/armband/files/nova-libvirt-aarch64-rollup.diff && cd /usr/lib/python2.7/dist-packages && patch -p1 -R --dry-run -r - < /var/cache/salt/minion/files/base/armband/files/nova-libvirt-aarch64-rollup.diff'
{% endif %}
