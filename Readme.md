## Description
This is a utility that can be used to combine multiple dependabot Pull Requests
into one Pull Request.  Unfortunately this functionality is not yet built into
dependabot, but has been requested so hopefully someday soon we won't
need this utility. :)

## Instructions
### build the image
  - `docker-compose build --pull --no-cache`

### Setup docker-compose.override.yml
  - cp docker-compose.override.example.yml docker-compose.override.yml
  - Setup a volume mapped to `/service/repo` e.g. `../360-content-pass-admin-frontend:/service/repo`

### Setup config.yml
Defines the dendencies/sub-dependencies to update, the max version to update to and a commit message to use if there are changes
  - Use config.example.yml as an example
  - Example config entry `[tar, '> 2.2.2', "[Security] Bump tar from 2.2.1 to 2.2.2\nBumps [tar](https://github.com/npm/node-tar) from 2.2.1 to 2.2.2. **This update includes security fixes.** \n- [Release notes](https://github.com/npm/node-tar/releases)\n- [Commits](npm/node-tar@v2.2.1...v2.2.2)"]`
    - the first item in the array is the name of the
      dependency/sub-dependency
    - The second item defines a rule for versions that will be ignored.
      Above says the max version to upgrade to is `2.2.2`.
    - The third items is the commit message that will be used if changes
      to the dependency are made.

### Executing
  - Note: make sure the repo mounted at /service/repo is on a new branch based on the latest master.
  - `docker-compose run --rm app ruby update-script.rb`
  - Example output:
```
Updating tar.  Ignoring versions > 2.2.2
    - Updating /service/repo/yarn.lock
Updating lodash.mergewith.  Ignoring versions > 4.6.2
    - Updating /service/repo/yarn.lock
Updating lodash.  Ignoring versions > 4.17.15
    - Updating /service/repo/package.json
    - Updating /service/repo/yarn.lock
Updating lodash-es.  Ignoring versions > 4.17.15
    - Updating /service/repo/yarn.lock
Updating fstream.  Ignoring versions > 1.0.12
    SKIPPING fstream since no updates were found.
```

### Checking on what was updated
  - Open a terminal and go to the repo you updated above.
  - `git log`
    - will show you the commit messages for the changes
  - `git diff HEAD~n`
      - will show you the diff of the last `n` commits.  So if there
        were 4 commits `git diff HEAD~4`

### Finishing up
Push up the changes made to your repo and create PR.
