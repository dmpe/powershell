# https://stackoverflow.com/questions/2003505/how-do-i-delete-a-git-branch-locally-and-remotely

######################
###### This script should be executed manually, step by step
###### Use GitLab UI to control changes
######
###### This control script renames git branch, both locally and on the server.
###### It serves as "post-production-steps-for-new-release-spring-release"
######
###### The principle applied here is to:
######
######  1. delete branch from remote
######  2. rename branch locally
######  3. push a renamed branch to the server
######  4. check if devel-$future_release exists - either locally or on remote server,
######     then if not, create devel-cur-$future_release and push to server
######################

########### Edit your numbers here
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

# push this newly renamed branch to gitlab, will become protected branch
git push origin "prod-$release_in_question":"prod-$release_in_question"

# 2. rename next release to become devel-cur
# if devel-$future_release does not exist, use git checkout init-branch and there
#  git checkout -b devel-cur-$future_release
$dev_branch = 'devel-$future_release'

$locally_new_branch_exists = git show-ref refs/heads/$dev_branch
$remotely_new_branch_exists = git ls-remote --heads origin $dev_branch

If ($locally_new_branch_exists -ne $null -and $remotely_new_branch_exists -ne $null) {
    # use below to checkout init-file branch (e.g. it can contain some created folders, files, etc.)
    # and start a new release from there
    git checkout init-branch
    git checkout -b devel-cur-$future_release init-branch
} else {
    git branch -m $dev_branch "devel-cur-$future_release"
}

# push this newly renamed branch to gitlab
git push origin "devel-cur-$future_release":"devel-cur-$future_release"

# delete remote branch, making it clean
git push origin --delete --force $dev_branch

# check manually Git(Hub/Lab)
