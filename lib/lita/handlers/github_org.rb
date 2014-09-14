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
require 'lita-github/general'
require 'lita-github/config'
require 'lita-github/octo'
require 'lita-github/org'
require 'lita-github/filters'

module Lita
  # Lita Handler
  module Handlers
    # GitHub Lita Handler
    class GithubOrg < Handler
      include LitaGithub::General # Github handler common-use methods
      include LitaGithub::Config  # Github handler Lita configuration methods
      include LitaGithub::Octo    # Github handler common-use Octokit methods
      include LitaGithub::Org     # Github handler common-use Organization methods
      include LitaGithub::Filters # Github handler common-use method filters

      on :loaded, :setup_octo # from LitaGithub::Octo

      KNOWN_PERMS = %w(pull push admin)

      route(
        /#{LitaGithub::R::A_REG}(?:teams|org\s+?teams|org\s+?team\s+?list)(?<org>\s+[a-zA-Z0-9_\-]+)?/,
        :org_teams_list,
        command: true,
        help: {
          'gh org teams [organization]' => 'show all teams of an organization',
          'gh teams [organization]' => 'an alias for gh org teams'
        }
      )

      # rubocop:disable Metrics/LineLength
      route(
        # /#{LitaGithub::R::A_REG}org\s+?team\s+?add(?<org>\s+?[a-zA-Z0-9_\-]+)?(?<perm>\s+?[a-zA-Z]+)\s+?(?<name>.*)$/,
        /#{LitaGithub::R::A_REG}org\s+?team\s+?add(?<org>\s+?[a-zA-Z0-9_\-]+)?/,
        :org_team_add, command: true, confirmation: true,
        help: {
          'gh org team add PagerDuty name:"All Employees" perms:pull' => 'add an "All Engineers" team with pull permissions',
          'gh org team add PagerDuty name:Leads perms:pull' => 'add a "Leads" team with admin permissions',
          'gh org team add PagerDuty name:Ops perms:push' => 'add an "Ops" team with push permissions'
        }
      )
      # rubocop:enable Metrics/LineLength

      route(
        /#{LitaGithub::R::A_REG}org\s+?team\s+?rm(?<org>\s+?[a-zA-Z0-9_\-]+)?(?<team>\s+?[a-zA-Z0-9_\-]+)/,
        :org_team_rm, command: true, confirmation: true,
        help: {
          'gh org team rm PagerDuty ops' => 'delete the Operations team',
          'gh org team rm PagerDuty 42' => 'delete the team with id 42'
        }
      )

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

      def org_team_add(response)
        return response.reply(t('method_disabled')) if func_disabled?(__method__)

        opts = e_opts_parse(response.message.body)
        vo = validate_team_add_opts(opts)
        return response.reply(vo[:msg]) unless vo[:success]

        md = response.match_data
        org, perm, name = [organization(md['org'].strip), opts[:perms].strip.downcase, opts[:name]]

        return response.reply(
          t('org_team_add.perm_not_permitted', perms: config.org_team_add_allowed_perms.join(', '))
        ) unless permission_allowed?(perm)

        begin
          resp = octo.create_team(org, name: name, permission: perm)
        rescue Octokit::NotFound
          return response.reply(t('org_not_found', org: org))
        end

        response.reply(t('org_team_add.created_team', resp.to_h))
      end

      def org_team_rm(response)
        return response.reply(t('method_disabled')) if func_disabled?(__method__)

        md = response.match_data
        org, team = [organization(md['org'].strip), md['team'].strip]

        t_id = team_id(team, org)
        t = team?(t_id)

        return response.reply(t('team_not_found', team: team)) unless t

        if octo.delete_team(t_id)
          response.reply(t('org_team_rm.pass', t.to_h))
        else
          response.reply(t('org_team_rm.fail', t.to_h))
        end
      end

      private

      def validate_team_add_opts(opts)
        h = { success: true, msg: '' }
        h[:msg] << t('org_team_add.missing_option', opt: 'name') unless opts.key?(:name)
        h[:msg] << t('org_team_add.missing_option', opt: 'perms') unless opts.key?(:perms)
        h[:msg] << t('org_team_add.perm_invalid') if opts.key?(:perms) && !KNOWN_PERMS.include?(opts[:perms].downcase)
        h[:success] = false unless h[:msg].empty?
        h
      end

      def permission_allowed?(perm)
        config.org_team_add_allowed_perms.include?(perm)
      end
    end

    Lita.register_handler(GithubOrg)
  end
end
