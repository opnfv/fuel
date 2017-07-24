{% if grains['cpuarch'] == 'aarch64' %}
{% if grains['virtual'] == 'kvm' %}
nova_virt_type:
  file.replace:
    - name: "/etc/nova/nova.conf"
    - pattern: '^virt_type\s*=.*$'
    - repl: "virt_type = qemu"
nova_compute_virt_type:
  file.replace:
    - name: "/etc/nova/nova-compute.conf"
    - pattern: '^virt_type\s*=.*$'
    - repl: "virt_type = qemu"
{% endif %}
nova_pointer_model:
  file.replace:
    - name: "/etc/nova/nova.conf"
    - pattern: '^#pointer_model\s*=.*$'
    - repl: "pointer_model = ps2mouse"
nova_cpu_mode:
  file.replace:
    - name: "/etc/nova/nova.conf"
    - pattern:  '^cpu_mode\s*=\s*host-passthrough'
    - repl: "cpu_mode = custom"
nova_cpu_model:
  file.replace:
    - name: "/etc/nova/nova.conf"
    - pattern: '^#cpu_model\s*=.*$'
    {% if grains['virtual'] == 'kvm' %}
    - repl: "cpu_model = cortex-a57"
    {% else %}
    - repl: "cpu_model = host"
    {% endif %}
restart_nova-compute:
  cmd:
    - run
    - name: "service nova-compute restart"
{% endif %}
