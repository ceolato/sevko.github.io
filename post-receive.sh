#! /bin/bash

# Description:
#   Server-side git hook that compiles the site whenever new commits are
#   pushed.
#
# Use:
#   # from the repository root on the server
#   cd .git/hooks/
#   ln -s ../../post-receive.sh post-receive
#   cd -

cmd(){
	# Print a diagnostic message and execute a command. Print an error message
	# if it fails.

	echo $1
	${@:2} > /dev/null || (echo "Failed" && exit 1)
}

if ! [ -t 0 ]; then
	read -a ref
fi

IFS='/' read -ra REF <<< "${ref[2]}"
branch="${REF[2]}"

local repo_url=https://github.com/sevko/sevko.github.io
local repo_dest=/var/www/sevko.github.io

cmd "Cloning site." git clone --quiet $repo_url $repo_dest
cd $repo_dest
unset GIT_DIR

if [ $branch = staging ]; then
	cmd "Checking out staging." git checkout staging 2> /dev/null
	local site_dest=/var/www/staging.sevko.io
else
	local site_dest=/var/www/sevko.io
fi

cmd "Initializing submodules." git submodule update --init --quiet
cmd "Compiling resume." json_resume convert \
	--template=resume/custom.mustache --out=tex_pdf resume/resume.yaml
cmd "Compiling site." jekyll build

cd $site_dest
mv _site _old
cmd "Moving site." mv $repo_dest/_site .
cmd "Moving nginx config." mv $repo_dest/nginx.conf \
	/etc/nginx/sites-enabled/sevko.io
rm -rf _old
rm -rf $repo_dest
cmd "Restarting nginx." service nginx restart
echo "Build completed."
