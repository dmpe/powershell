#!/bin/bash
set -x

# Configure Nexus3 after installation
#
# Call this script with parameters:
#   $1: Nexus UserID
#   $2: Nexus Password
#   $3: Nexus URL

# Add a MAVEN Proxy Repo to Nexus3
# add_nexus3_proxy_repo [repo-id] [repo-url] [nexus-username] [nexus-password] [nexus-url]
# add_nexus3_proxy_repo redhat-ga https://maven.repository.redhat.com/ga/ $1 $2 $3
function add_nexus3_proxy_repo() {
  local _REPO_ID=$1
  local _REPO_URL=$2
  local _NEXUS_USER=$3
  local _NEXUS_PWD=$4
  local _NEXUS_URL=$5
  local _VERSION_POLICY=$6
  echo "debug: " $_REPO_ID $_REPO_URL $_NEXUS_USER $_NEXUS_PWD $_NEXUS_URL
  cd /tmp

  echo '{
    "name": "'${_REPO_ID}'",
    "type": "groovy",
    "content": "import org.sonatype.nexus.blobstore.api.BlobStoreManager;import org.sonatype.nexus.repository.storage.WritePolicy;import org.sonatype.nexus.repository.maven.VersionPolicy;import org.sonatype.nexus.repository.maven.LayoutPolicy;repository.createMavenProxy('\'${_REPO_ID}\'','\'${_REPO_URL}\'','\'default\'', false, VersionPolicy.'${_VERSION_POLICY}', LayoutPolicy.PERMISSIVE)"
  }' > nexus3repo2.json


  #  Create a Maven proxy repository.
  #  @param name The name of the new Repository
  #  @param remoteUrl The url of the external proxy for this Repository
  #  @param blobStoreName The BlobStore the Repository should use
  #  @param strictContentTypeValidation Whether or not the Repository should enforce strict content types
  #  @param versionPolicy The {@link VersionPolicy} for the Repository
  #  @param layoutPolicy The {@link LayoutPolicy} for the Repository
  #  @return the newly created Repository
  #

  $dbg curl -X POST "${_NEXUS_URL}/service/rest/v1/script" -H "accept: application/json" -H "Content-Type: application/json" --data @nexus3repo2.json -u "$_NEXUS_USER:$_NEXUS_PWD"  --verbose
  curl -v -X POST -H "Content-Type: text/plain" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/$_REPO_ID/run"
}

#
# Add a MAVEN HOSTED Release Repo to Nexus3
# add_nexus3_release_repo [repo-id] [nexus-username] [nexus-password] [nexus-url]
# add_nexus3_hosted_repo releases $1 $2 $3
function add_nexus3_hosted_repo() {
  local _REPO_ID=$1
  local _NEXUS_USER=$2
  local _NEXUS_PWD=$3
  local _NEXUS_URL=$4
  local _VERSION_POLICY=$5
  cd /tmp

  #  Create a Maven hosted repository.
  #  @param name The name of the new Repository
  #  @param blobStoreName The BlobStore the Repository should use
  #  @param strictContentTypeValidation Whether or not the Repository should enforce strict content types
  #  @param versionPolicy The {@link VersionPolicy} for the Repository
  #  @param writePolicy The {@link WritePolicy} for the Repository
  #  @param layoutPolicy The {@link LayoutPolicy} for the Repository
  #  @return the newly created Repository

  echo '{
    "name": "'${_REPO_ID}'",
    "type": "groovy",
    "content": "import org.sonatype.nexus.blobstore.api.BlobStoreManager;import org.sonatype.nexus.repository.storage.WritePolicy;import org.sonatype.nexus.repository.maven.VersionPolicy;import org.sonatype.nexus.repository.maven.LayoutPolicy;repository.createMavenHosted('\'${_REPO_ID}\'','\'default\'', false, VersionPolicy.'${_VERSION_POLICY}', WritePolicy.ALLOW,LayoutPolicy.PERMISSIVE)"
  }' > nexus3repo2.json

  curl -v -H "Accept: application/json" -H "Content-Type: application/json" --data @nexus3repo2.json -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/"
  curl -v -X POST -H "Content-Type: text/plain" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/rest/v1/script/$_REPO_ID/run"
}


