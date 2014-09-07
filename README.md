lita-github
===========
[![Build Status](https://img.shields.io/travis/PagerDuty/lita-github/master.svg)](https://travis-ci.org/PagerDuty/lita-github)
[![Code Climate Coverage](http://img.shields.io/codeclimate/coverage/github/PagerDuty/lita-github.svg)](https://codeclimate.com/github/PagerDuty/lita-github)
[![RubyGems :: lita-github Gem Version](http://img.shields.io/gem/v/lita-github.svg)](https://rubygems.org/gems/lita-github)
[![MIT License](https://img.shields.io/badge/license-Apache%202.0-brightgreen.svg)](https://tldrlegal.com/license/apache-license-2.0-(apache-2.0))

Copyright 2014 PagerDuty, Inc.

Lita handler for GitHub-related operations. This include administrative management of organizations and repository management/operations.

This project was born out of the Aug 22, 2014 HackDay at PagerDuty.

Under Development
-----------------
This Gem is currently in development, and is not suited for production use. There will probably be bugs.

In addition, the documentation will be lacking while the development is underway.

Configuration
-------------
The configuration options will get their own in-depth doc a little further down the line. Here are the important ones for now:

* `config.handlers.github.access_token = ''`
  * Your GitHUb access token (generated from Settings > Security > Personal Applications)
  * This is an administrative utility, so the token will need pretty wide access to leverage this plugin fully
* `config.handlers.github.default_org = ''`
  * Your company may only have one organization, the handler will allow you to type just the repo name (`lita-github`) instead of `PagerDuty/lita-github`.
* `config.handlers.github.default_team_slug = ''`
  * if no team is provided when adding a repo, it uses this team by default -- if unset, only owners can access repo
  * the default team that should be added to a repo based on the slug name:
    * When clicking on a team in your org you can use the URL to get the slug: https://github.com/orgs/<ORG>/teams/[slug]

Commands
--------
Use the source, Luke. We will try to keep this list up to date, but it will be inevitably deprecated by proper documentation.

The command support two prefixes, assuming you have the `robot_alias` set to `!`:
* `!gh <command>`
* `!github <command>`

Here is the current functionality:

### GitHub Main Handler

* `!gh status`
  * get the current system status for GitHub
* `!gh version`
  * get the version of handler
* `!gh token`
  * generate a TOTP token if `config.handlers.github.totp_secret` is set in the config

### GitHub Repository Handler
* `!gh repo create PagerDuty/lita-github private:true team:<team_slug>`
  * This creates a new repository, sets it to private, and adds the team you've specified.
  * This method can be disabled by setting `config.handlers.github.repo_create_enabled = false` in your configuration file
* `!gh repo delete PagerDuty/lita-github`
  * Deletes the repo you specify, requires confirmation before doing so
  * **Note:** This method is disabled by default, you need to enable it by setting `config.handlers.github.repo_delete_enabled = true` in your configuration file

### Github PR Handler
* `!gh pr info #42 PagerDuty/lita-github`
  * output some information about the PR. Such as: state (open|closed|merged), build status, user who opened, user who merged, amongst others...
* `!gh pr merge #42 PagerDuty/lita-github` or `!shipit #42 PagerDuty/lita-github`
  * This merges the specified pull request
  * This method can be disabled by setting `config.handlers.github.pr_merge_enabled = false` in your configuration file
* `!gh pr list PagerDuty/lita-github`
  * list the open pull requests on a repo
