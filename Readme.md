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
    - `package_manager` defines the package manager the repo we are
      updating utilizes.  Informs dependabot which files to look for.
      Currently supports `npm_and_yarn` (node projects) and `bundler`
      (ruby projects).
    - `dependency_updates` defines a list of dependencies/sub-dependencies
       and the information needed to update them.
      - `name` is the name of the dependency/sub-dependency
      - `ignore_versions` defines a rule for versions that will be ignored.
        e.g. `> 2.2.2` says the max version to upgrade to is `2.2.2`.
      - `commit_message` is the commit message that will be used if changes
        to the dependency are made.

`config.yml` is volumed into the container from the base directory of
this project.

### Executing
  - Note: make sure the repo mounted at /service/repo is on a new branch based on the latest master.
  - `docker-compose run --rm app ruby update.rb`
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
