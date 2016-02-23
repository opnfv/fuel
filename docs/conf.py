# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2016 Linux Foundation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# Copied from releng/docs/etc/conf.py
extensions = ['sphinxcontrib.httpdomain',
              'sphinx.ext.autodoc',
              'sphinx.ext.viewcode',
              'sphinx.ext.napoleon']

needs_sphinx = '1.3'
master_doc = 'index'
pygments_style = 'sphinx'

html_use_index = False
numfig = True
html_logo = 'opnfv-logo.png'

latex_domain_indices = False
latex_logo = 'opnfv-logo.png'

# addtional config
latex_elements = {'figure_align': 'H'}
