# -*- coding: UTF-8 -*-
#
# Copyright 2014 PagerDuty, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module LitaGithub
  # Github handler common-use Repository methods
  module Repo
    # Maximum number of allowed PRs to be returned when listing
    #
    # @author Tim Heckman <tim@pagerduty.com>
    PR_LIST_MAX_COUNT = 20

    # Combine org and repo to get the canonical name
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @param org [String] organization name
    # @param repo [String] repository name without org prefixed
    # @return [String] canonical name of repo: <Org>/<Repo>
    def rpo(org, repo)
      "#{org}/#{repo}"
    end

    # Determine if r is a Github repository
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @param r [String] canonical name of the repository
    def repo?(r)
      octo.repository?(r)
    end

    # Helper method for pulling widely used matches out of a MatchData object
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @param md [MatchData] the match data used to get the matches
    # @return [Array] [0] is the org name, [1] is the repo name
    def repo_match(md)
      [organization(md['org']), md['repo']]
    end

    # Determine if the team is already on the repository
    #
    # @param full_name [String] the canonical name of the repository
    # @param team_id [Integer] the id for the Github team
    # @return [TrueClass] if the team is already on the repo
    # @return [FalseClass] if the team is not on the repo
    def repo_has_team?(full_name, team_id)
      octo.repository_teams(full_name).each { |t| return true if t[:id] == team_id }
      false
    end
  end
end
