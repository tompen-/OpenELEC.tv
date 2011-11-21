#!/bin/sh

#Get the official XBMC source
git clone git://github.com/xbmc/xbmc.git /tmp/xbmc_source

# change directory to the xbmc source code repository
cd /tmp/xbmc_source
git pull

# Create a branch based on the exact xbmc version that openelec currently uses
# When creating the pathc, this is the branch we will be comparing with.
git checkout -b xbmc_openelec c68ef0b1daed399fd88638d62646d5531bc12cae
# replace b44b653 above with the commit id that is used by openelec
# The commit used by Openelev can be seen in the openelec source file, packages/mediacenter/xbmc/meta

#Add spotyxbmc2 to our repository:
git remote add spotyxbmc2 git://github.com/akezeke/spotyxbmc2.git
git fetch spotyxbmc2
git checkout --track -b spotyxbmc2 spotyxbmc2/master

# ----Optional step-----
# This can be done if you want to avoid updating xbmc to the latest spotyxbmc2 version:
# The goal with this optional step is to create a branch with the same spotyxbmc2 date/time
# as the xbmc version that is currently used by openelec.
# You can easily Compare latest entries in git log to find a suitable commit in the spotyxbmc2
# branch that are that have the same message as the latest commin in our xbmc_openelec branch.
#
# git log xbmc_openelec
# git log
# git checkout xxxxxxx
#
# (replace xxxxxxx above with your desired commit)
# --End of optional step--

# Create a branch for the spotyxbmc2 version that we will use in the patch.
git checkout -b spotyxbmc2_patch_baseline

# Switch to openelec branch:
git checkout xbmc_openelec

# We need a temporary branch that we will use for the patch creation.
git checkout -b tmpsquash

# Merge all changes done in the spotyxbmc source code to our temporary branch.
# Note: If conflicts are reported by this git merge, you must resolve it manually
# by editing the relevant files. (When I did this, I did not not get any conflicts)
git merge --squash spotyxbmc2_patch_baseline

#Commit our merge. The message text here will become our patch filename later.
# For me, 560af9fc7b was the last commit that I had in the branch spotyxbmc2_patch_baseline.
# You can use "git log spotyxbmc_patch_baseline" to find the last commit.
git commit -a -m "spotyxbmc2-560af9fc7b-Spotify-support-for-xbmc"

# Create our patch (we are excluding any changes made to confluence skin):
git format-patch --unified=3 xbmc_openelec -- $(git ls-files | grep -v -e skin.confluence -e project)

# As a note, the only change in the skin is addition of a audio flagging icon.
# When compiling, this icon image will be copied by the openelec skin install script.

cd -
mv /tmp/xbmc_source/00*.patch .

#cleanup
cd /tmp/xbmc_source
git checkout  master
git branch -D  spotyxbmc2
git branch -D  spotyxbmc2_patch_baseline
git branch -D  tmpsquash
git branch -D  xbmc_openelec
cd -
