---
layout: post
title: "Jekyll : Handling Github page build failure and Jekyll plugins on Github"
---

__Updated 18-Nov-2013 : publish.sh script updated to publish a specific commit__ [ [jump to this](#UPDATE18NOV2013) ]

I recently got the shock of my life when I could no longer publish new posts on my website since jekyll build on Github was failing possibly due to an upgrade of jekyll version that Github uses to build jekyll sites. However I observed that I was able to build my site locally without any problems. After some investigation into the problem, I found that I could build my site locally rather that have Github build it for me, and thus overcome these Github page build failures. I also found out that this method can be used to maintain a jekyll site that uses jekyll plugins which Github won't build for you (jekyll plugins are not allowed on Github pages). Here is a very simple step-by-step solution to the problem, with zero down-time for your jekyll site.

- First you need to create a new branch on Github to hold your site's source code. Currently, this is your master branch on Github. Let us move it to another branch called source.

        $ git checkout -b source master

  This command creates another branch called source which mirrors your current master branch. Essentially we are making a copy of the history on your master branch.

- Go ahead and push this new branch to Github

        $ git push -u origin source

  Now, if you login to your Github account and browse the repository which holds your jekyll site, you should see two branches(master and source).

- Now, make source as your default branch on Github by entering the repository specific settings which you can see to the right of repository file listing on Github. This is done so that, anybody visiting your repository on Github will see the source code for your site(which is on the source branch) and not the pre-built jekyll site (which we will eventually push to the master branch). Also, anyone who clones your repository will get the source branch automatically checked out instead of the pre-built HTML that is on your master branch.

- Now, coming to your master branch, which currently holds the source for your jekyll site. The master branch will now contain the pre-built HTML that you built locally. Building your site locally and pushing the HTML to the master branch of your Github repository is pretty easy, but it easily becomes frustrating when you have to do it everytime you make a change to your site or add a new post. So, I have created a [small shell script]({% link /assets/publish.sh %}) which does just that in a single command and which I use to publish new posts on this website.

Do make the necessary changes to the shell script such as the actual jekyll command that you use to build your site locally(on line  12) and the name of your Github repository(on line 21).

Push your modified publish.sh shell script to the source branch of your repository so that you always have the script where you need it. Now, publishing any new posts or making any changes to your site is as simple as the following command.

    $ cd <your_local_clone_of_github_repo>
    $ ./publish.sh

Sit back and enjoy while your jekyll site is built and pushed to the master branch, and thus served to the masses with no problem at all.

<a id="UPDATE18NOV2013"></a>
<br />

__UPDATE (18-NOV-2013)__

I see two advantages to this method compared to pushing to master.

- __No dependency on GitHub's jekyll build system__. As long as you are able to "jekyll serve" your webpage on your local machine, you can be sure that is what you will see on your github site.

- Having a seperate branch just for your sources allows you to __commit partial articles__ which you can resume writing another time possibly on another computer. And you can be sure that GitHub won't try to build your partial articles and serve them. To accomplish this, I have updated my publish.sh script(see link above) to publish only the commit you specify(instead of the HEAD commit). And the new publish.sh script also ignores all untracked files and uncommitted changes while publishing.

Here is how to use the new publish.sh script

    $ cd <your_local_clone_of_github_repo>
    $ ./publish.sh <optional_commit_sha1>

If you don't specify the commit SHA1 which you want to specifically publish, the HEAD commit is taken as the default.
