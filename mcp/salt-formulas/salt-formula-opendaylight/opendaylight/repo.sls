##############################################################################
# Copyright (c) 2019 Mirantis Inc. and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
{% from "opendaylight/map.jinja" import server with context %}

# NOTE: starting with Salt 2018.3, key_text might be used instead
opendaylight_repo_key:
  # Launchpad PPA for ODL Team
  # pub   4096R/44C05248 2017-01-26
  cmd.run:
  - name: |
      cat <<-EOF | sudo apt-key add -
      -----BEGIN PGP PUBLIC KEY BLOCK-----
      Version: GnuPG v1

      mQINBFiKaBEBEADpCtIj8utf/bUfN6iQ+sxGiOPLnXVYoYyKifHDazD4o1Jevfiu
      EpcDIx9EdnhrCpvKTU+jaw2B7K3pkdqbjbzjZY+2CDENSQXfRHuuI/nWDaYI0stx
      Tf/evip3cxdutnZNAklzkxppHP+4UZm9HAd7uZsEyff4H9DIsHzZIA4Z++Hx2+lt
      w9K0iCKh2k6Pon/VVo8Bir3JuKIIdLRAuHmyniYlHDswQnu+1nQHE0F/oboD0Q9Z
      hOvXAr1L7LWu0hkLV7BqmeI0SPcRA3b5MU3dfaTK8MaPAo8anQTpCyYUnoIBqX8h
      y324T/dvpFKq2/X3RL+wOSYTA8TLgyhH0fhdIKZg3G8m9kxuAHZYHIHnDtvgJ5yd
      72tNY+w8UIX8U2ark/WdkAMZr3O0AuTDlvHcasxO5+puAu8jh0EgtqItqrvKwiF7
      dmlHVW41Rt+su2fmsUkk4Z0IhWrn3PdrSWAcH2eL6vjuqx6CccpjsjyiSQ90dUox
      EoMpY+viX59aF0kU4BLt76mQO6YZtCpicLxFGCu97v1mNn+FWjhBOIF08pVsbNlq
      oMl2j0N8NKZxJvkkmsA/i//ch5FsjzvUy3xajlSzq9ruWS4SlWq2Vzdx/acvF7Oa
      ABA11wIjzLc9vmhzQNiRa53fJQwi+w/Or9LtH2msKCbcPVHoZ5OT4t6S8QARAQAB
      tBpMYXVuY2hwYWQgUFBBIGZvciBPREwgVGVhbYkCOAQTAQIAIgUCWIpoEQIbAwYL
      CQgHAwIGFQgCCQoLBBYCAwECHgECF4AACgkQe4qho0TAUkgAmg//XY/RqU4WcT+p
      13oDc3+Dp4aL+rwaNz0o56i0z0cYPxd8GPicCuS8d/di07GnQiBcZ5DZgegnnaYm
      OUF+phxk4q+jYO/t2GHQlYSf/QyUv7OimidLOHN1FiahmcGobliwih70o6ZcMT84
      ggSu8jBzA/HLFBIkgStKD/staR5zJ2HfK298yVhiffyrPA+I3nPe7pvTaGa2e8AP
      BYs5zB5n27upSZIokXFvqlmS4HEKDmPcY061wgmg1cNY1Y+mIuGjxY1Igbi6kAe0
      yaLN2AN4c2ImhpwOcuazKTe/q2ZhoPTpYvuzmogwau8LBjRBhVS6fkTpSBPEkcwn
      f/QYmmVLygmpMDHuHapyH8iaUoksq7gd64iBRDJQN7giQSjkTVvcGBqoKG8lbUMV
      MDT4FGuYYsObWUg7kmHlNq9nIVlAxmxv8ZTg9+8xy3f53aId/51m+gW9LGRAT94T
      ZIWrF9cBvsPWoHgHkV1At/fPprOvNXqeQiJ7UzC3ikDNCu2AjPEbA4sb019RNgtj
      jUI6g6RZdzbeKVpptxILCtT3yKbfKj8AfrfaRzS0yMhVudgLolIUA4S6g46p0Cgy
      gITO49wxxBu6UAOsAG3psDRlsZmmrT4AH09Yt2RzmY0FBWValqpoPagheQqeU+2W
      FKnV9Lw1SKMtWZbYMvIlB0rwts3k9lE=
      =xkZ9
      -----END PGP PUBLIC KEY BLOCK-----
      EOF
  - unless: apt-key list | grep -qF '4096R/44C05248 2017-01-26'

opendaylight_repo:
  pkgrepo.managed:
  # NOTE(armband): PPA handling behind proxy broken, define it explicitly
  # https://github.com/saltstack/salt/pull/45224
  # - ppa: {{ server.repo }}
  - human_name: opendaylight-ppa
  - name: deb http://ppa.launchpad.net/{{ server.repo }}/ubuntu {{ grains.oscodename }} main
  - file: /etc/apt/sources.list.d/odl-team-{{ server.version }}.list
