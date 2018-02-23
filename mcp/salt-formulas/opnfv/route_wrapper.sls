##############################################################################
# Copyright (c) 2018 Mirantis Inc., Enea AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
/usr/local/sbin/route:
  file.managed:
    - contents: |
        #!/bin/sh

        # Workaround salt-managed routes breaking ifup when route already exists
        route_binary='/sbin/route'
        route_output=$("${route_binary}" "$@" 2>&1)
        route_return=$?

        if [ -n "${route_output}" ]; then
            if echo "${route_output}" | grep -q 'SIOCADDRT: File exists'; then
                exit 0
            fi
            echo "${route_output}"
        fi
        exit "${route_return}"
    - user: root
    - group: root
    - mode: 755
