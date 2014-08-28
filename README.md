lita-github
===========
[![Build Status](https://img.shields.io/travis/PagerDuty/lita-github/master.svg)](https://travis-ci.org/PagerDuty/lita-github)
[![MIT License](https://img.shields.io/badge/license-Apache%202.0-brightgreen.svg)](https://tldrlegal.com/license/apache-license-2.0-(apache-2.0))
[![RubyGems :: lita-github Gem Version](http://img.shields.io/gem/v/lita-github.svg)](https://rubygems.org/gems/lita-github)
[![Code Climate Quality](https://img.shields.io/codeclimate/github/PagerDuty/lita-github.svg)](https://codeclimate.com/github/PagerDuty/lita-github)
[![Code Climate Coverage](http://img.shields.io/codeclimate/coverage/github/PagerDuty/lita-github.svg)](https://codeclimate.com/github/PagerDuty/lita-github)
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
* `config.handlers.default_org = ''`
  * Your company may only have one organization, the handler will allow you to type just the repo name (`lita-github`) instead of `PagerDuty/lita-github`.
* `config.handlers.default_team_slug = ''`
  * the default team that should be added to a repo based on the slug name:
    * When clicking on a team in your org you can use the URL to get the slug: https://github.com/orgs/<ORG>/teams/[slug]

Commands
--------
Use the source, Luke. We will try to keep this list up to date, but it will be inevitably deprecated by proper documentation.

The command support two prefixes, assuming you have the `robot_alias` set to `!`:
* `!gh <command>`
* `!github <command>`

Here is the current functionality:

* `!gh status`
  * get the current system status for GitHub
* `!gh version`
  * get the version of handler
