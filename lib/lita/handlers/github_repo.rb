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
require 'lita-github/repo'
require 'lita-github/filters'

module Lita
  # Lita Handler
  module Handlers
    # GitHub Lita Handler
    class GithubRepo < Handler
      include LitaGithub::Config  # Github handler Lita configuration methods
      include LitaGithub::Octo    # Github handler common-use Octokit methods
      include LitaGithub::Org     # Github handler common-use Organization methods
      include LitaGithub::Repo    # Github handler common-use Repository methods
      include LitaGithub::Filters # Github handler common-use method filters

      on :loaded, :setup_octo # from LitaGithub::Octo

      route(
        /#{LitaGithub::R::A_REG}repo\s+?(?:create|new)\s+?#{LitaGithub::R::REPO_REGEX}.*$/,
        :repo_create,
        command: true,
        help: {
          'gh repo create PagerDuty/lita-github private:true team:heckman' =>
            'Create the PagerDuty/lita-github repo, make it private, use team with "heckman" slug',
          'gh repo new PagerDuty/lita-github' =>
            'create new repo using the default privacy/team settings'
        }
      )

      route(
        /#{LitaGithub::R::A_REG}repo\s+?delete\s+?#{LitaGithub::R::REPO_REGEX}/,
        :repo_delete, command: true, confirmation: true,
        help: {
          'gh repo delete PagerDuty/lita-github' => 'Delete the PagerDuty/lita-github repo'
        }
      )

      route(
        /#{LitaGithub::R::A_REG}repo\s+?info\s+?#{LitaGithub::R::REPO_REGEX}/,
        :repo_info,
        command: true,
        help: {
          'gh repo info PagerDuty/lita-github' => 'Display some information about the repo'
        }
      )

      def repo_create(response)
        return response.reply(t('method_disabled')) if func_disabled?(__method__)

        org, repo = repo_match(response)

        if repo?(rpo(org, repo))
          return response.reply(t('repo_create.exists', org: org, repo: repo))
        end

        opts = extrapolate_create_opts(command_opts(response.args.join(' ')), org)

        response.reply(create_repo(org, repo, opts))
      end

      def repo_delete(response)
        return response.reply(t('method_disabled')) if func_disabled?(__method__)

        org, repo = repo_match(response)

        return response.reply(t('repo_delete.not_found', org: org, repo: repo)) unless repo?(rpo(org, repo))

        response.reply(delete_repo(org, repo))
      end

      def repo_info(response)
        org, repo = repo_match(response)
        full_name = rpo(org, repo)
        opts = {}
        r_obj = octo.repository(full_name)
        p_obj = octo.pull_requests(full_name)

        opts[:repo]             = r_obj[:full_name]
        opts[:description]      = r_obj[:description]
        opts[:private]          = r_obj[:private]
        opts[:url]              = r_obj[:html_url]
        opts[:raw_issues_count] = r_obj[:open_issues_count]
        opts[:pr_count]         = p_obj.length
        opts[:issues_count]     = opts[:raw_issues_count] - opts[:pr_count]

        response.reply(t('repo_info.reply', opts))
      end

      private

      def command_opts(cmd)
        o = {}
        cmd.scan(LitaGithub::R::OPT_REGEX).flatten.compact.each do |opt|
          k, v = opt.strip.split(':')
          k = k.to_sym
          o[k] = v unless o.key?(k)
        end
        o
      end

      # TODO: convert this to a mixin method for reuse
      def repo_match(response)
        md = response.match_data
        [organization(md['org']), md['repo']]
      end

      def extrapolate_create_opts(opts, org)
        opts[:organization] = org

        if opts.key?(:team)
          opts[:team_id] = team_by_slug(opts[:team], org) || team_by_slug(config.default_team_slug, org)
        else
          opts[:team_id] = team_by_slug(config.default_team_slug, org)
        end unless opts.key?(:team_id)
        opts
      end

      def team_by_slug(slug, org)
        octo.organization_teams(org).each do |team|
          return team[:id] if team[:slug] == slug
        end
        nil
      end

      def should_repo_be_private?(value)
        if value.nil? || value.empty?
          config.repo_private_default
        else
          privacy_decider(value)
        end
      end

      def privacy_decider(value)
        case value.downcase
        when 'true'
          true
        when 'false'
          false
        else # when some invalud value...
          config.repo_private_default
        end
      end

      def create_repo(org, repo, opts)
        full_name = rpo(org, repo)
        reply = nil
        begin
          octo.create_repository(repo, opts)
        ensure
          if repo?(full_name)
            repo_url = "https://github.com/#{full_name}"
            reply = t('repo_create.pass', org: org, repo: repo, repo_url: repo_url)
          else
            reply = t('repo_create.fail', org: org, repo: repo)
          end
        end
        reply
      end

      def delete_repo(org, repo)
        full_name = rpo(org, repo)
        reply = nil
        begin
          octo.delete_repository(full_name)
        ensure
          if repo?(full_name)
            reply = t('repo_delete.fail', org: org, repo: repo)
          else
            reply = t('repo_delete.pass', org: org, repo: repo)
          end
        end
        reply
      end
    end

    Lita.register_handler(GithubRepo)
  end
end
