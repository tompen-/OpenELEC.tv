#!/bin/sh

#################################################################################
#
#  This script file is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this software.  If not, write to:
#  Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA
#  http://www.gnu.org/copyleft/gpl.html
#################################################################################

if [ -z "$1" ]; then
  echo
  echo "This script converts the spotyxbmc2 source code changes for xbmc into a"
  echo "patchfile that is suitable for use when compiling xbmc on OpenELEC."
  echo
  echo "Usage: $0 commit=<SHA>"
  echo "This creates a patchfile based on your specified commit SHA that must be"
  echo "a valid commit in the spotyxbmc2 github repository."
  echo
  echo "or"
  echo
  echo "Usage: $0 branch=<name>"
  echo "This creates a patchfile based on the most recent commit in your specified"
  echo "branch that must be a valid branch that exist in the spotyxbmc2 github repository."
  echo
  echo "Example:"
  echo "$0 branch=master"
  echo
  exit 1
fi

echo Please wait..
echo

#If not done before, clone the official XBMC source to local repository
if [ -e /$HOME/patchcreate_xbmc_source ]
then
  # This script have been run before, we only need to pull the latest xbmc source code from repository.
  cd $HOME/patchcreate_xbmc_source
  git fetch origin
else
  # First time we run this script, we need to clone the complete xbmc source code repository.
  git clone git://github.com/xbmc/xbmc.git $HOME/patchcreate_xbmc_source
  cd $HOME/patchcreate_xbmc_source

  # Add spotyxbmc2 remote repository to our local repository:
  git remote add spotyxbmc2 git://github.com/akezeke/spotyxbmc2.git
fi

# Create a branch for official xbmc master.
git branch xbmc_master origin/master

# Create a branch for official xbmc Eden.
git branch eden origin/Eden

# Update with the latest source code from the remote spotyxbmc2 repository.
git fetch spotyxbmc2

# Create a branch with the selected spotyxbmc2 source code.
if [ `echo $1 | cut -c -6` = commit ]; then
  git branch spotyxbmc2 `echo $1 | cut -c 8-`
fi

if [ `echo $1 | cut -c -6` = branch ]; then
  git branch spotyxbmc2 spotyxbmc2/`echo $1 | cut -c 8-`
fi

# Need to remember the last commit in the selected spotyxbmc2 source for our patch filename.
SPOTYXBMC2_LAST_COMMIT=$(git log spotyxbmc2 | head -n 1 | cut -c 8-17)

echo Create a branch at the last xbmc commit that is also included in spotyxbmc2 fork.
echo That last commit is:
git merge-base xbmc_master spotyxbmc2
git branch last_common $(git merge-base xbmc_master spotyxbmc2)

echo Need to merge also the Eden branch changes that akezeke have merged to spotyxbmc2 master.
echo The commits to be merged are:
git merge-base --all eden spotyxbmc2
git checkout -b temp_eden $(git merge-base --all eden spotyxbmc2)

echo Reverting Eden specific commits that cause merge conflicts with master branch.
echo Reverting Eden specific splash image commits
git revert --no-edit 30312f116857c5e00d202638928215b2e5f18eb6
git revert --no-edit 1fef727af39c0c6e5264ee14fe4c78f8567f035e
git revert --no-edit f76c547eda2945f535093d1a0f24a1ecaf43eb9b
git revert --no-edit 379d13c8e9a0e64f1f36b3fb216e5caedb0df73e

echo Reverting Eden specific version string bumps.
git revert --no-edit 04d4066d2f6ea573aa365a030816329b0006253b
git revert --no-edit f38655f1b565926846c1e17e0e7801c811037b1f
git revert --no-edit 998687de644fa25dcc27cf2e6e1a5522e09224f6
git revert --no-edit 52e9d21510e3d4330322d7a8962c42b8f00cec76
git revert --no-edit fd08f6d3f3d0de9fbdbc1db20ee5e5ffa26d7a83
git revert --no-edit 8d7d09f70bd01ff97cb90ef8ab1e348a28b24559

echo Reverting Eden specific packaging files
git revert --no-edit bbd922c60231f76c131af53228b774b21c5009cc

echo cherry-pick splash image from master branch
git cherry-pick 8c04e3a47715e87da5e23088e1ec6085c443bea6

git checkout last_common
git merge --no-edit temp_eden

# We need a temporary branch that we will use for the spotyxbmc2 patch creation.
git checkout -b tmpsquash

# Merge all changes done in the spotyxbmc source code to our temporary branch.
git merge --squash spotyxbmc2

# Commit our merge. The message text here will become our patch filename later.
git commit -a -m "spotyxbmc2-$SPOTYXBMC2_LAST_COMMIT-Spotify-support-for-xbmc"

# Create our patch (we are excluding any changes made to confluence skin):
git format-patch --unified=3 last_common -- $(git ls-files | grep -v -e skin.confluence -e project)

# As a sidenote, the only spoyxbmc2 change in the skin is addition of a audio flagging icon.
# When compiling, this icon image will be copied by the openelec skin install script.

cd -
mv $HOME/patchcreate_xbmc_source/00*.patch .

# Cleanup, here we prepare so we can run this script again.
cd $HOME/patchcreate_xbmc_source

git checkout master
git branch -D temp_eden spotyxbmc2 tmpsquash last_common eden xbmc_master
cd -

echo
echo =============================================================================
echo
echo Script is now finished. Please look for your patchfile in this directory:
pwd
echo
echo A repository that includes the last official xbmc source code was created in:
echo $HOME/patchcreate_xbmc_source
echo You might want to delete this directory to save some disk space.
echo If you keep the folder untouched, it will greatly reduce the time and effort
echo to run this script again some other day in the future.
echo =============================================================================
