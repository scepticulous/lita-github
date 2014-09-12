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

require 'lita-github/r'
require 'lita-github/config'
require 'lita-github/octo'
require 'lita-github/org'

module Lita
  # Lita Handler
  module Handlers
    # GitHub Lita Handler
    class GithubOrg < Handler
      include LitaGithub::Config  # Github handler Lita configuration methods
      include LitaGithub::Octo    # Github handler common-use Octokit methods
      include LitaGithub::Org     # Github handler common-use Organization methods

      on :loaded, :setup_octo # from LitaGithub::Octo

      # rubocop:disable Metrics/LineLength
      route(
        /#{LitaGithub::R::A_REG}(?:teams|org\s+?teams|org\s+?team\s+?list)(?<org>\s+[a-zA-Z0-9_\-]+)?/,
        :org_teams_list,
        command: true,
        help: {
          'gh org teams [organization]' => 'show all teams of an organization',
          'gh teams [organization]' => 'an alias for gh org teams'
        }
      )
      # rubocop:enable Metrics/LineLength

      def org_teams_list(response)
        md = response.match_data
        org = md[:org].nil? ? config.default_org : organization(md[:org].strip)

        begin
          teams = octo.organization_teams(org)
        rescue Octokit::NotFound
          return response.reply(t('org_not_found', org: org))
        end

        tl = teams.length

        o = teams.shift

        reply = t('org_teams_list.header', org: org, num_teams: tl)
        reply << t('org_teams_list.team', o.to_h)

        sort_by_name(teams).each { |team| reply << t('org_teams_list.team', team.to_h) }

        response.reply(reply)
      end
    end

    Lita.register_handler(GithubOrg)
  end
end
