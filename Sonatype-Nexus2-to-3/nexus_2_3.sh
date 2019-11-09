#!/bin/bash

export PATH=/usr/local/bin:/usr/bin:/bin

set -eE -o pipefail

self="$(readlink -mn "${BASH_SOURCE[0]}")"
base="$(dirname "$(dirname "$(dirname "$self")")")"

_setup() {
  echo "Setting up variables and scripts"

  nexus2="https://nexus2"
  nexus3="https://nexus-3"
  nexus2file=nexus2_repositories.xml
  nexus2filejson=nexus2_repositories.json
  nexus3file=nexus3_repositories.json
  nexus3scripts=nexus3_scripts.json
  declare -a nexus3repos=()
  declare -a nexus2repos=()
  declare -a parsed_st=()

  $dbg source ./nexus_api.sh || true

  read -r -p "Nexus 3 username: " username3
  echo "Nexus 3 password: "
  read -s password3

  true

}

_download_nxt2_repositories() {
  _banner "Downloading Repositories from Nexus 2"
  local _rest_endp="service/local/all_repositories"

  read -r -p "Nexus 2 username: " username
  echo "Nexus 2 password: "
  read -s password

  printf "User %s has been setup. \n" "$username"

  $dbg curl -GET -u "$username":"$password" \
    --url $nexus2/$_rest_endp --output /tmp/$nexus2file \
    --header 'accept: application/xml'

  $dbg curl -GET -u "$username":"$password" \
    --url $nexus2/$_rest_endp --output /tmp/$nexus2filejson \
    --header 'accept: application/json'

  true
}

_download_nxt3_repositories() {
  _banner "Downloading Repositories from Nexus 3"
  local _rest_endp="service/rest/v1/repositories"

  printf "User %s has been setup. \n" "$username"

  $dbg curl -GET -u "$username3":"$password3" \
    --url $nexus3/$_rest_endp --output /tmp/$nexus3file \
    --header 'content-type: application/json'
  true
}

_extract_repositories_nxt3() {
  nexus3repos=($(jq -r '.[] | {name: .name|tostring} | join("")' /tmp/$nexus3file))

  for repo in "${nexus3repos[@]}"; do
    echo "$repo"
  done

  true
}

_extract_repositories_nxt2() {
  nexus2repos=($(jq -r '.data[] | {id: .id|tostring} | join("")' /tmp/$nexus2filejson | tr '[:upper:]' '[:lower:]'))
  declare -a nexus2repoInfo=($(jq -r '.data[] | [.id, .repoType, .remoteUri] | @tsv' /tmp/$nexus2filejson ))

  for repo in "${nexus2repoInfo[@]}"; do
    echo "$repo"
  done

  true
}

_create_target_repositories() {
   _banner "Create new (empty) repositories on the target Nexus 2"

  # for each name in array size
  # https://unix.stackexchange.com/a/193042

  echo "${!nexus2repos[@]}"

  for i in "${!nexus2repos[@]}"; do
    word=${nexus2repos[$i]}
    echo "key:" "$i" "value:" "$word"

    repoType=$(jq -r '.data['$i'] | .repoType|tostring' /tmp/$nexus2filejson)
    url=$(jq -r '.data['$i'] | .remoteUri|tostring' /tmp/$nexus2filejson)
    repoPolicy=$(jq -r '.data['$i'] | .repoPolicy|tostring' /tmp/$nexus2filejson)

    # echo "the repo type is: ->" "$repoType"

    if [[ $repoType == "proxy" ]]; then

      if printf '%s\n' ${nexus3repos[@]} | grep -q "${word[@]}"; then
        # TODO if our repo on Nexus 3 already exists && and if it is not in excluded ones
        echo "do nothing"
      else
        echo "starting creating new repo"
        add_nexus3_proxy_repo "$word" "$url" "$username3" "$password3" "$nexus3" "$repoPolicy"
      fi

    elif [[ $repoType == "hosted" ]]; then

      echo "hosted REPO!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      add_nexus3_hosted_repo "$word" "$username3" "$password3" "$nexus3" "$repoPolicy"

    else
      printf "SKIP. the repository %s is not a type of proxy, group or hosted \n" "$word";

    fi

  done
}

_delete_scripts_repos() {
  curl -GET --url "$nexus3/service/rest/v1/script" -u $username3:$password3 -H "accept: application/json" > /tmp/$nexus3scripts
  parsed_st=($(jq -r '.[] | {name: .name|tostring} | join("")' /tmp/$nexus3scripts))

  for i in "${parsed_st[@]}"; do
    echo "Deleting $i script from Nexus3"

    curl -X DELETE --url "$nexus3/service/rest/v1/script/$i" \
         -H "accept: application/json" \
         -u $username3:$password3

  done
}


_main() {

  _setup

  _download_nxt2_repositories
  _extract_repositories_nxt2

  _download_nxt3_repositories
  _extract_repositories_nxt3

  _create_target_repositories
  _delete_scripts_repos
}

_main "$@"
