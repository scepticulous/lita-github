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
require 'lita-github/repo'
require 'lita-github/filters'

module Lita
  # Lita Handler
  module Handlers
    # GitHub Issues Lita Handler
    class GithubIssues < Handler
      include LitaGithub::General # Github handler common-use methods
      include LitaGithub::Config  # Github handler Lita configuration methods
      include LitaGithub::Octo    # Github handler common-use Octokit methods
      include LitaGithub::Org     # Github handler common-use Organization methods
      include LitaGithub::Repo    # Github handler common-use Repository methods
      include LitaGithub::Filters # Github handler common-use method filters

      on :loaded, :setup_octo # from LitaGithub::Octo

      # issue states
      LI_STATES = %w(open closed all)
      # issue states
      LI_SM     = %w(created updated comments)
      # sort direction
      LI_DIR    = %w(asc desc)

      route(
        /#{LitaGithub::R::A_REG}(?:issues|repo\s+?issues)\s+?#{LitaGithub::R::REPO_REGEX}/,
        :issues_list,
        command: true,
        help: {
          'gh issues PagerDuty/lita-github' => 'list the issues on a repo',
          'gh issues PagerDuty/lita-github state:closed sort:updated sort:desc' => 'just showing some option usage'
        }
      )

      # This is the handler for listing issues on a repository
      # @author Tim Heckman <tim@pagerduty.com>
      def issues_list(response)
        full_name = rpo(*repo_match(response.match_data))
        opts = opts_parse(response.message.body)

        oops = validate_list_opts(opts)

        return response.reply(oops) unless oops.empty?

        return response.reply(t('repo_not_found', repo: full_name)) unless repo?(full_name)

        # get the issues that are not pull requests
        begin
          issues = octo.list_issues(full_name, opts).reject { |i| i.key?(:pull_request) }
        rescue Octokit::UnprocessableEntity => e
          return response.reply(t('issues_list.invalid_opts', m: e.message))
        rescue StandardError => e
          return response.reply(t('boom', m: e.message))
        end

        if issues.empty?
          reply = t('issues_list.none', r: full_name)
        else
          reply = t('issues_list.header', n: issues.length, r: full_name)
          issues.each { |i| reply << t('issues_list.item',  i.to_h.merge(u: i[:user][:login], r: full_name)) }
        end

        response.reply(reply)
      end

      private

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      #
      # Validate the command options
      #
      # @param opts [Hash] the key:value pairs from the command
      # @return [String] the response to reply with if there was a validation failure
      def validate_list_opts(opts)
        resp = ''
        resp << t('issues_list.val_states') if opts.key?(:state) && !LI_STATES.include?(opts[:state])
        resp << t('issues_list.val_sort') if opts.key?(:sort) && !LI_SM.include?(opts[:sort])
        resp << t('issues_list.val_direction') if opts.key?(:direction) && !LI_DIR.include?(opts[:direction])
        resp = "Invalid option(s):\n#{resp}" unless resp.empty?
        resp
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end

    Lita.register_handler(GithubIssues)
  end
end
