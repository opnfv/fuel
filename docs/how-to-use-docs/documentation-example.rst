.. two dots create a comment. please leave this logo at the top of each of your rst files.
.. image:: ../etc/opnfv-logo.png 
  :height: 40
  :width: 200
  :alt: OPNFV
  :align: left
.. these two pipes are to seperate the logo from the first title
|
|
How to create documentation for your OPNFV project
==================================================

this is the directory structure of the docs/ directory that can be found in the root of your project directory

.. code-block:: bash

    ./etc
    ./etc/opnfv-logo.png
    ./etc/conf.py
    ./how-to-use-docs
    ./how-to-use-docs/documentation-example.rst
    ./how-to-use-docs/index.rst

To create your own documentation, Create any number of directories (depending on your need) and place in each of them an index.rst.
This index file must refence your other rst files.

* Here is an example index.rst

.. code-block:: bash

  Example Documentation table of contents
  =======================================

  Contents:

  .. toctree::
     :numbered:
     :maxdepth: 4

     documentation-example.rst

  Indices and tables
  ==================

  * :ref:`search`

  Revision: _sha1_

  Build date: |today|


The Sphinx Build
================

When you push documentation changes to gerrit a jenkins job will create html documentation.

* Verify Jobs
For verify jobs a link to the documentation will show up as a comment in gerrit for you to see the result.

* Merge jobs

Once you are happy with the look of your documentation you can submit the patchset the merge job will 
copy the output of each documentation directory to http://artifacts.opnfv.org/$project/docs/$name_of_your_folder/index.html

Here are some quick examples of how to use rst markup

This is a headline::

  here is some code, note that it is indented

links are easy to add: Here is a link to sphinx, the tool that we are using to generate documetation http://sphinx-doc.org/

* Bulleted Items

  **this will be bold**

.. code-block:: bash

  echo "Heres is a code block with bash syntax highlighting"


Leave these at the bottom of each of your documents they are used internally

Revision: _sha1_

Build date: |today|
