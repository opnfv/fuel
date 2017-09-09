.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. http://creativecommons.org/licenses/by/4.0
.. (c) 2017 Mirantis Inc., Enea AB and others.

Fuel@OPNFV submodule fetching and patching
==========================================

This directory holds submodule fetching/patching scripts, intended for
working with upstream Fuel/MCP components (e.g.: reclass-system-salt-model) in
developing/applying OPNFV patches (backports, custom fixes etc.).

The scripts should be friendly to the following 2 use-cases:
  - development work: easily cloning, binding repos to specific commits,
    remote tracking, patch development etc.;
  - to provide parent build scripts an easy method of tracking upstream
    references and applying OPNFV patches on top;

Also, we need to support at least the following modes of operations:
  - submodule bind - each submodule patches will be based on the commit ID
    saved in the .gitmodules config file;
  - remote tracking - each submodule will sync with the upstream remote
    and patches will be applied on top of <sub_remote>/<sub_branch>/HEAD;

Workflow (development)
----------------------
The standard development workflow should look as follows:

1. Decide whether remote tracking should be active or not:
   NOTE: Setting the following var to any non-empty str enables remote track.
   NOTE: Leaving unset will enable remote track for anything but stable branch.

   $ export FUEL_TRACK_REMOTES=""

2. All Fuel sub-projects are registered as submodules. To initialize them, call:
   If remote tracking is active, upstream remote is queried and latest remote
   branch HEAD is fetched. Otherwise, checkout commit IDs from .gitmodules.

   $ make sub

3. Apply patches from `patches/<sub-project>/*` to respective submodules via:

   $ make patches-import

   This will result in creation of:
   - a tag called `${FUEL_MAIN_TAG}-opnfv-root` at the same commit as Fuel@OPNFV
     upstream reference (bound to git submodule OR tracking remote HEAD);
   - a new branch `opnfv-fuel` which will hold all the OPNFV patches,
     each patch is applied on this new branch with `git-am`;
   - a tag called `${FUEL_MAIN_TAG}-opnfv` at `opnfv-fuel/HEAD`;

4. Modify sub-projects for whatever you need.
   Commit your changes when you want them taken into account in the build.

5. Re-create patches via:

   $ make patches-export

   Each commit on `opnfv-fuel` branch of each subproject will be
   exported to `patches/subproject/` via `git format-patch`.

   NOTE: Only commit (-f) submodules when you need to bump upstream ref.
   NOTE: DO NOT commit patched submodules!

6. Clean workbench branches and tags with:

   $ make clean

7. De-initialize submodules and force a clean clone with:

   $ make deepclean

Sub-project maintenance
-----------------------
1. Adding a new submodule
   If you need to add another subproject, you can do it with `git submodule`.
   Make sure that you specify branch (with `-b`), short name (with `--name`):

   $ git submodule -b master add --name reclass-system-salt-model \
     https://github.com/Mirantis/reclass-system-salt-model \
     relative/path/to/submodule

2. Working with remote tracking for upgrading Fuel components
   Enable remote tracking as described above, which at `make sub` will update
   ALL submodules (e.g. reclass-system-salt-model) to remote branch (set in
   .gitmodules) HEAD.

   * If upstream has NOT already tagged a new version, we can still work on
     our patches, make sure they apply etc., then check for new upstream
     changes (and that our patches still apply on top of them) by:

   $ make deepclean patches-import

   * If upstream has already tagged a new version we want to pick up, checkout
     the new tag in each submodule:

   $ git submodule foreach 'git checkout <newtag>'

   * Once satisfied with the patch and submodule changes, commit them:
     - enforce FUEL_TRACK_REMOTES to "yes" if you want to constatly use the
       latest remote branch HEAD (as soon as upstream pushes a change on that
       branch, our next build will automatically include it - risk of our
       patches colliding with new upstream changes);
     - stage patch changes if any;
     - if submodule tags have been updated (relevant when remote tracking is
       disabled, i.e. we have a stable upstream baseline), add submodules:

   $ make deepclean sub && git add -f relative/path/to/submodule
