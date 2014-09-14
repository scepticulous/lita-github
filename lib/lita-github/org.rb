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
  # Github handler common-use Organization methods
  #
  # @author Tim Heckman <tim@pagerduty.com>
  module Org
    # Uses default organization if one provided is nil or empty string
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @param name [String,Nil] the name of the organization
    # @return [String] the name of the organization to use
    def organization(name)
      name.nil? || name.empty? ? config.default_org : name
    end

    # Sorts a list of Github team objects by name
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @param teams [Array<Teams>] pass in the teams you want to sort by name
    # @return [Array] the teams but sorted by name
    def sort_by_name(teams)
      teams.sort_by { |h| h[:name].downcase }
    end

    # Get the Github team ID using its slug
    #
    # This depends on the `octo()` method from LitaGithub::Octo being within the same scope
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @param slug [String] the slug of the team you're getting the ID for
    # @param org [String] the organization this team should belong in
    # @return [Nil] if no team was found nil is returned
    # @return [Integer] if a team is found the team's ID is returned
    def team_id_by_slug(slug, org)
      octo.organization_teams(org).each do |team|
        return team[:id] if team[:slug] == slug
      end
      nil
    end

    # Get the team id based on either the team slug or the team id
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @param team [String,Integer] this is either the team's slug or the team's id
    # @return [Integer] the team's id
    def team_id(team, org)
      /^\d+$/.match(team.to_s) ? team : team_id_by_slug(team, org)
    end

    # Check if a team exists
    #
    # @param id [Integer] the id number for the team
    # @return [Sawyer::Resource(Github team)] if team exists
    # @return [FalseClass] if team does not exist
    def team?(id)
      octo.team(id)
    rescue Octokit::NotFound
      false
    end
  end
end
