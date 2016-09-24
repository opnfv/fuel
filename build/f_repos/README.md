Fuel@OPNFV submodule fetching and patching
==========================================

This directory holds submodule fetching/patching scripts, intended for
working with upstream Fuel components (fuel-library, ... , fuel-ui) in
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

Workflow (ISO build)
--------------------
Parent build scripts require this mechanism to do some fingerprinting,
so here is the intended flow for all artifacts to be generated right:

1. (Optional) Cached submodules might be fetched from build cache.

2. Submodules are updated
   We also dump each submodule's git info using repo_info.sh, since
   we want to collect git refs before patching (i.e. upstream refs).

3. Make target `release` is built
   This will make sure the modules are in a clean state, put them in cache,
   then apply the patches.

4. fuel-main's `${FUEL_MAIN_TAG}-opnfv-root` tag is used to determine VERSION info
   It will accommodate both bound tags and remote tracking references.

Sub-project maintenance
-----------------------
1. Adding a new submodule
   If you need to add another subproject, you can do it with `git submodule`.
   Make sure that you specify branch (with `-b`), short name (with `--name`)
   and point it to `upstream/*` directory, i.e.:

   $ git submodule -b stable/mitaka add --name fuel-web \
     https://github.com/openstack/fuel-web.git upstream/fuel-web
