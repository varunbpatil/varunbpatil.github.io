#!/bin/bash
#
# script to build website and push it to github

# signal handler
function cleanup
{
    rm -rf /tmp/jekyll_build
    rm -rf /tmp/varunbpatil.github.com
    exit 0
}

trap cleanup SIGHUP SIGINT SIGTERM

# verify number of arguments
if [ $# -gt 1 ]; then
    echo "$(tput setaf 1)Incorrect command usage. Usage : $0 <optional_commit_sha1>$(tput sgr0)"
    exit 1
fi

# first argument (if any) is the commit SHA1
if [ $# -eq 1 ]; then
    SHA1=$1
else
    SHA1="HEAD"
fi
echo "$(tput setaf 2)Going to publish commit ${SHA1}. Press any key to continue.$(tput sgr0)"
read

# create a tmp dir into which jekyll will build the html source
if [ -d "/tmp/jekyll_build" ]; then
    rm -rf /tmp/jekyll_build
fi
mkdir /tmp/jekyll_build

# get a clean copy of the repo(current directory) in /tmp
cp -r $PWD /tmp/ >&/dev/null
cd /tmp/varunbpatil.github.com
git clean -fd >&/dev/null
git reset --hard $SHA1 >&/dev/null

# build website
jekyll build -d /tmp/jekyll_build/

# publish on github only if jekyll build was successful
if [ $? -eq 0 ]; then
    cd /tmp/jekyll_build
    git init
    git add .
    publish_date=`date`
    git commit -m "updated site ${publish_date}"
    git remote add origin git@github.com:varunbpatil/varunbpatil.github.com.git
    git push origin master --force

    echo "$(tput setaf 2)Successfully built and published to github...$(tput sgr0)"
else
    echo "$(tput setaf 1)Jekyll build failed... not publishing to github$(tput sgr0)"
fi

# cleanup
cleanup