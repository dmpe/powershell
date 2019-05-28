# https://stackoverflow.com/questions/2003505/how-do-i-delete-a-git-branch-locally-and-remotely


######################
###### This script must be executed manually, step by step
###### Use GitLab UI to control changes
######################

########### Edit your branch number here
$release_in_question='9.0.3.2390.02'
$future_release='9.0.3.2390.03'

git checkout master

# get latest from remote
git pull --all

# start with remotes: delete remote branch named devel-cur-*
#git push origin --delete --force $(git branch --list 'devel-cur-*')
git push origin --delete --force "devel-cur-$release_in_question"

# 1. rename local branch to a different name
git branch -m "devel-cur-$release_in_question" "prod-$release_in_question"

# push this newly renamed branch to git repo on server
git push origin "prod-$release_in_question":"prod-$release_in_question"

# 2. rename next release to become devel-cur
git branch -m "devel-$future_release" "devel-cur-$future_release"

# push this newly renamed branch to gitlab
git push origin "devel-cur-$future_release":"devel-cur-$future_release"

# delete remote branch, making it clean
git push origin --delete --force "devel-$future_release"

# use below to checkout init-file branch and start new release from there
git checkout -b "devel-$future_release" init_branch
