.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. SPDX-License-Identifier: CC-BY-4.0
.. (c) 2018 Mirantis Inc., Enea AB and others.

==========================================
OPNFV Fuel Submodule Fetching and Patching
==========================================

This directory holds submodule fetching/patching scripts, intended for
working with upstream Fuel/MCP components (e.g.: ``reclass-system-salt-model``)
in developing/applying OPNFV patches (backports, custom fixes etc.).

The scripts should be friendly to the following 2 use-cases:

- development work: easily cloning, binding repos to specific commits,
  remote tracking, patch development etc.;
- to provide parent build scripts an easy method of tracking upstream
  references and applying OPNFV patches on top;

Also, we need to support at least the following modes of operations:

- submodule bind - each submodule patches will be based on the commit ID
  saved in the ``.gitmodules`` config file;
- remote tracking - each submodule will sync with the upstream remote
  and patches will be applied on top of ``<sub_remote>/<sub_branch>/HEAD``;

Workflow (Development)
======================

The standard development workflow should look as follows:

Decide whether remote tracking should be active or not
------------------------------------------------------

.. NOTE::

    Setting the following var to any non-empty str enables remote track.

.. code-block:: console

    developer@machine:~/fuel$ export FUEL_TRACK_REMOTES=""

Initialize git submodules
-------------------------

All Fuel direct dependency projects are registered as submodules.
If remote tracking is active, upstream remote is queried and latest remote
branch ``HEAD`` is fetched. Otherwise, checkout commit IDs from ``.gitmodules``.

.. code-block:: console

    developer@machine:~/fuel$ make -C mcp/patches sub

Apply patches from ``patches/<sub-project>/*`` to respective submodules
-----------------------------------------------------------------------

This will result in creation of:

- a tag called ``${F_OPNFV_TAG}-root`` at the same commit as OPNFV Fuel
  upstream reference (bound to git submodule OR tracking remote ``HEAD``);
- a new branch ``nightly`` which will hold all the OPNFV patches,
  each patch is applied on this new branch with ``git-am``;
- a tag called ``${F_OPNFV_TAG}`` at ``nightly/HEAD``;
- for each (sub)directory of ``patches/<sub-project>``, another pair of tags
  ``${F_OPNFV_TAG}-<sub-directory>-fuel/patch-root`` and
  ``${F_OPNFV_TAG}-<sub-directory>-fuel/patch`` are also created;

.. code-block:: console

    developer@machine:~/fuel$ make -C mcp/patches patches-import

Modify sub-projects for whatever you need
-----------------------------------------

To add/change OPNFV-specific patches for a sub-project:

- commit your changes inside the git submodule(s);
- move the git tag to the new reference so ``make patches-export`` will
  pick up the new commit later;

.. code-block:: console

    developer@machine:~/fuel$ cd ./path/to/submodule
    developer@machine:~/fuel/path/to/submodule$ # ...
    developer@machine:~/fuel/path/to/submodule$ git commit
    developer@machine:~/fuel/path/to/submodule$ git tag -f ${F_OPNFV_TAG}-fuel/patch

Re-create Patches
-----------------

Each commit on ``nightly`` branch of each subproject will be
exported to ``patches/subproject/`` via ``git format-patch``.

.. NOTE::

    Only commit submodule file changes when you need to bump upstream refs.

.. WARNING::

    DO NOT commit patched submodules!

.. code-block:: console

    developer@machine:~/fuel$ make -C mcp/patches patches-export patches-copyright

Clean Workbench Branches and Tags
---------------------------------

.. code-block:: console

    developer@machine:~/fuel$ make -C mcp/patches clean

De-initialize Submodules and Force a Clean Clone
------------------------------------------------

.. code-block:: console

    developer@machine:~/fuel$ make -C mcp/patches deepclean

Sub-project Maintenance
=======================

Adding a New Submodule
----------------------

If you need to add another subproject, you can do it with ``git submodule``.
Make sure that you specify branch (with ``-b``), short name (with ``--name``):

.. code-block:: console

    developer@machine:~/fuel$ git submodule -b master add --name reclass-system-salt-model \
                              https://github.com/Mirantis/reclass-system-salt-model \
                              mcp/reclass/classes/system

Working with Remote Tracking
----------------------------

Enable remote tracking as described above, which at ``make sub`` will update
ALL submodules (e.g. ``reclass-system-salt-model``) to remote branch (set in
``.gitmodules``) ``HEAD``.

.. WARNING::

    Enforce ``FUEL_TRACK_REMOTES`` to ``yes`` only if you want to constatly
    use the latest remote branch ``HEAD`` (as soon as upstream pushes a change
    on that branch, our next build will automatically include it - risk of our
    patches colliding with new upstream changes) - for **ALL** submodules.
