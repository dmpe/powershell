#!/bin/bash

# Adjusted from https://gist.github.com/DarthHater/a4f2738e3bd40d242db22633b59dfd63 and 
# https://github.com/sonatype-nexus-community/nexus-repository-import-scripts/pull/6/files

while getopts ":r:u:p:" opt; do
  case $opt in
    r) REPO_URL="$OPTARG"
    ;;
    u) USERNAME="$OPTARG"
    ;;
    p) PASSWORD="$OPTARG"
    ;;
  esac
done

find . -type f -not -path '*/\.*' \
      -not -path '*/\^archetype\-catalog\.xml*' \
      -not -path '*/\^maven\-metadata\-local*\.xml' \
      -not -path '*/\^maven\-metadata\-deployment*\.xml' \
      -not -path '*.sh' | sed "s|^\./||" | xargs -I '{}' curl -v -u ${USERNAME}:${PASSWORD} -X PUT -T {} ${REPO_URL}/repository/maven-releases/{} ;
