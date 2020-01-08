{% if grains['cpuarch'] == 'aarch64' %}
/usr/local/sbin/lvcreate:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - contents: |
        #!/bin/bash
        /sbin/lvcreate -vvv $@
{% endif %}
