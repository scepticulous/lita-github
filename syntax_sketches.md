Lita + GitHub syntax sketches
=============================
These sketches were originally made by Eric Sigler (@esigler) at PagerDuty. They are being added
to the repo just for development purposes. This file will be removed later on.

As a note, these are the results of brainstorming. They in no way indicate the final syntax, nor
should they be treated as the end-all-be-all for how the commands should look. Follow convention
and do what feels right.

### Committers
```
github commiters <repo> - shows commiters of repository
github commiters top <repo> - shows top commiters of repository
```

### Issues
```
github issues show <repo> - List all issues for given repo
github issues show mine - List all issues for user
github issues show all - List all issues for all followed repos
github issues new <repo> <issue> - List all issues for given repo
github issues delete <issue ID> - List all issues for given repo
```

### Pull Requests
```
github pr <pr #> merge - Merge a pull request
shipit <pull request>  - Add a :shipit: squirrel to a PR
```

### Merging
```
github merge project_name/<head> into <base> - merges the selected branches or SHA commits
```

### Repositories
```
github repo new
github repo add committer
github repo show <repo> - shows activity of repository
```

### Searches
```
github search <query> [repo] - Search for <query> in [repo] or anywhere
```

### Github site status
```
github status - Returns the current system status and timestamp
github status last - Returns the last human communication, status, and timestamp
github status messages - Returns the most recent human communications with status and timestamp
github status stalk [seconds] - Returns the last human communication, status, and timestamp, watches [seconds, default 60] for updates, and posts if it changes
```

### Misc.
```
github identify <email address>
github whoami
github forget
```