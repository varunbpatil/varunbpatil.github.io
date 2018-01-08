---
layout: post
title: "GitHub project contribution workflow"
---

I only recently started contributing to other projects on GitHub, and while I am quite comfortable with the normal git workflow, I had never given a thought about how to use git to contribute to other projects (especially on GitHub). Although, I found many articles on the web, most of them were too complex to follow or missed out on some parts. So, I put together the good bits I found around the web and here it is.

#### Fork

* Login to your GitHub account.

* Goto the GitHub page of the project you intend to contribute to.

* Click on the __fork__ button (top right).

You should now have a new repository on your GitHub page with the words "forked from ____" under the name of your repository.

#### Clone

* Clone your GitHub repository (__not__ the original project repo that you just forked). For example, I did

        $ git clone git@github.com:varunbpatil/openh264.git

  Where the main project GitHub repo that I intended to contribute to was git@github.com:cisco/openh264.git

- Set upstream repository.

  Your repository is not automatically kept to date with the original project repo. You have to do it manually. So, first set the upstream repo like so.

        $ git remote add upstream git@github.com:cisco/openh264.git

- To update your local repo to match the original project repo (also called upstream), do

        $ git pull upstream master

  This updates your repo's master branch with the updates from the upstream repo's (original project repo's) master branch.

- Push any master branch updates to your GitHub repo (so that your GitHub repo itself is kept up to date with the main project repo and not just your local clone).

        $ git push origin master

  Note that you are not contributing anything by doing this. You are simply keeping the master branch of your repository up to date with the master branch of the upstream repo.

#### Contribute

- Create a new branch to make a new contribution (a new feature or a bug fix, etc).

        $ git checkout -b my_new_feature_1

  You will notice that after the above command you are automatically put on the my\_new\_feature\_1 branch and not the master branch of your repo. Confirm this by typing

        $ git branch

  You should see a * (asterisk) next to the branch my\_new\_feature\_1.

  It is recommended that you keep the master branch of your repo clean, and do not make any changes (or contributions) on top of your master branch (although it can be done if you intend to make a quick contribution, a one time contribution).

- Make as many commits as you like on this branch and push to your repository on GitHub.

        $ git push origin my_new_feature_1

  This creates the branch my\_new\_feature\_1 on your GitHub repo as well. This branch only existed on your local cloned repo until now.

- Now, you can ask the maintainers of the original project to consider your contributions by making a __pull request__.

  To do so, goto the GitHub webpage of __your__ repo and then change the branch to my\_new\_feature\_1 from the drop down menu just below the repo stats (the default branch shown on the web page is Master branch).

  Next, click on the "Pull Request" link which should be on the line below the drop down menu alongside the "Compare" link (__not__ the "Pull Requests" tab on the sidebar on the right).

  Review the changes that you are going to submit, write a short description explaining your changes and then go ahead and submit the pull request.

  Now, goto the web page of the main GitHub project that you forked, click on the "Pull Requests" tab on the right hand sidebar. You should see the pull request that your just made along with possibly other pull requests that others have made.

- Wanna make more changes and contributions after a pull request has been submitted ?

  Sure, no problem. Continue to make commits to the my\_new\_feature\_1 branch of your repository and push them to your repository.

        $ git push origin my_new_feature_1

  You __don't__ need to issue another pull request for the new commit. These new commits are automatically added to the pull request you made earlier provided that you committed to the same branch (my\_new\_feature\_1). GitHub's policy is __one pull request per branch__.

- Want to add another new feature ? Why not... Just create another branch for your new feature and follow the same steps.

        $ git checkout master
        $ git checkout -b my_new_feature_2
        $ #make some commits in this branch
        $ git push origin my_new_feature_2

  Goto the web page of your GitHub repo, select the my\_new\_feature\_2 branch from the drop down menu, click on the "Pull Request" link, review and submit the pull request. Voila !!!

- All is well until someone review's your pull request and suggests that you make some changes for your contributions to be accepted into the original project's repo. There are two approaches to this.

  The first approach is to make more commits on top of the commits you have already submitted addressing any issues. But, I don't prefer this method, since it creates unnecessary commits, thus dirtying the commit history of the repo.

  Since, the project's maintainers haven't yet merged your commit's into the main repo, you are better of rewriting the commit history of your repo. This way your have a cleaner commit history with no unwanted commits and your new commits do exactly the same job as before while considering the suggestions made by the person(s) who reviewed your pull request(s). However, never use this method when several people are contributing to your repo (i.e, when others have cloned your repo, and are making changes on the same branch that you are).

  I won't go into details of the exact git commands that you need to use to rewrite commit history, but the following are probably the ones you are looking for (not in any order).

        $ git reset --soft # remove commit, but keep changes
        $ git rebase -i # reorder commits, squash commits, split commits
        $ git commit --amend # change commit message

  Once you are done with the changes, make them visible to the project's maintainers.

        $ git push origin my_new_feature_1 -f # forcefully change commit history

 Your pull request will automatically be changed to reflect your newly modified commits. There is __no need__ to issue another pull request.

- Congratulations... Your contributions have been merged into the original project and your pull request has been closed. What next ?

 Delete the branch that the pull request corresponds to on your cloned copy as well as on your GitHub repo.

    $ git checkout master
    $ git branch -d my_new_feature_1 # deletes local branch
    $ git push origin :my_new_feature_1 # deletes remote branch

  Note that the colon in the last command above is intentional.

  Note that you also get a link on the GitHub web page to delete the branch corresponding to the pull request once the pull request has been closed.

  Verify that your contributions have indeed been merged into the original project repo.

    $ git pull upstream master
    $ git log # should see your commits here
    $ git push origin master

#### Miscellaneous

- Closing a pull request prematurely.

  Suppose you want to cancel a pull request before it has been merged into the main project repo, goto your pull request on the original project repo's webpage and click the "close" link and the bottom of the webpage (just below the comment boxes). You may also reopen a pull request at a later point of time from the webpage.

<br /><br /><br /><br /><br />
Any question or suggestions are welcome in the comments below. Happy contributing :)
