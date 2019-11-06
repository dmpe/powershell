# Nexus 2 to 3 Transition

:warning: Scripts in this repository require significant changes.
They should be used just as rough ideas to further work on.

## Goals

- Strive to have minimal impact on projects - but not mantra
- Test before goes to final Nexus 3

### Approach

1. download current repos, in JSON, from 2

2. parse JSON file from nexus 2

  2.2. extract links via `jq`

3. automate creation of Nexus 2 repos on Nexus 3

**Step 1: Repo Configuration**

```
  for each repository item nexus 2

    extract id, type, url from 2 -> store in array

    if type is proxy and is not in excluded=(Oracle alx_releases)

      check Nexus 3 with `jq` if name already exists
        if does, skip - do nothing
        if does not, then create new repo
      else
        skip

    if type is hosted
      check Nexus 3 with `jq` if name already exists

    if type is group
      CREATE MANUALLY
```

**Step 2: Move hosted artifacts to Nexus 3**

- <https://gist.github.com/DarthHater/a4f2738e3bd40d242db22633b59dfd63>

- Alternatively <https://support.sonatype.com/hc/en-us/articles/115006744008-How-can-I-programmatically-upload-files-into-Nexus-3->

- one can use `mvn` CLI

## Use

Find your nexus 2 `storage` folder, navigate to the desired repository, and copy `nexus_bulk_upload.sh`
Be careful, because it will start uploading every artefact to the nexus 3. You may want to do a clean up before.
Call with `./nexus_bulk_upload.sh -u username -p password -r nexus3URL`

## Sources

Source/Inspiration from <https://github.com/oballest/advdev_homework/blob/3817aa41daa826c0ec4d6b0707430ad24f5b02c3/Infrastructure/bin/setup_nexus3.sh>

#### Nexus API for Repositories

- Doc: <https://help.sonatype.com/repomanager3/rest-and-integration-api/script-api>
- Nexus Java API <https://github.com/sonatype/nexus-public/blob/master/plugins/nexus-script-plugin/src/main/java/org/sonatype/nexus/script/plugin/RepositoryApi.java>
