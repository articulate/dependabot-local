# Dependabot local

## Description
This is a utility that can be used to combine multiple dependabot pull requests
into one pull request.  Unfortunately this functionality is not yet built into
dependabot, but has been requested so hopefully someday soon we won't
need this utility. :)

Currently it supports ruby and node projects, but could be updated to
work for any of the languages that dependabot supports.
See this [section](#Adding-support-for-another-language's-package-manager) below for more details

## Instructions
### build the image
  - `docker-compose build --pull --no-cache`

### Setup docker-compose.override.yml
  - cp docker-compose.override.example.yml docker-compose.override.yml
  - Setup a volume mapped to `/service/repo` e.g.
    `/your/local/repo/path/here:/service/repo`

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
  - `docker-compose run --rm app`
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

## Adding support for another language's package manager
First you need to add the native helper gem for the package manager to
the Gemfile. A list can be found at https://rubygems.org/search?utf8=%E2%9C%93&query=dependabot-
  - edit `Gemfile` adding the new dependency.  e.g. `gem dependabot-dep`
    for go's package manager
  - `docker-compose build --pull --no-cache`

Then you'll need to copy the native helper files and build them as
described here https://github.com/dependabot/dependabot-script#native-helpers.

Dockerfile currenly contains the necessary commands to get the
`npm_and_yarn` native helper setup
