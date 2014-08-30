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
  # Lita handler
  module Handlers
    # Handler class for GitHub PR management
    class GithubPR < Handler
      include LitaGithub::R       # Github handler common-use regex constants
      include LitaGithub::Config  # Github handler Lita configuration methods
      include LitaGithub::Octo    # Github handler common-use Octokit methods
      include LitaGithub::Org     # Github handler common-use Organization methods
      include LitaGithub::Repo    # Github handler common-use Repository methods
      include LitaGithub::Filters # Github handler common-use method filters

      on :loaded, :setup_octo # from LitaGithub::Octo

      route(
        /(?:#{LitaGithub::R::A_REG}(?:pr merge|shipit)|shipit)\s+?#(?<pr>\d+?)\s+?#{LitaGithub::R::REPO_REGEX}/,
        :pr_merge, command: true, confirmation: true,
        help: {
          'gh shipit #42 PagerDuty/lita-github' => 'ship it!',
          'gh pr merge #42 PagerDuty/lita-github' => 'ship it!',
          'shipit #42 PagerDuty/lita-github' => 'ship it!'
        }
      )

      def pr_merge(response)
        return response.reply(t('method_disabled')) if func_disabled?(__method__)
        org, repo, pr = pr_match(response)

        begin
          pr_obj = octo.pull_request(rpo(org, repo), pr)
        rescue Octokit::NotFound
          return response.reply(t('not_found', pr: pr, org: org, repo: repo))
        end

        branch = pr_obj[:head][:ref]
        title = pr_obj[:title]
        commit = "Merge pull request ##{pr} from #{org}/#{branch}\n\n#{title}"

        status = merge_pr(org, repo, pr, commit)

        if !defined?(status) || status.nil?
          response.reply(t('exception'))
        elsif status[:merged]
          response.reply(t('pr_merge.pass', pr: pr, org: org, branch: branch, title: title))
        else
          url = "https://github.com/#{org}/#{repo}/pull/#{pr}"
          response.reply(t('pr_merge.fail', pr: pr, title: title, url: url, msg: status[:message]))
        end
      end

      private

      def pr_match(response)
        md = response.match_data
        [organization(md['org']), md['repo'], md['pr']]
      end

      def merge_pr(org, repo, pr, commit)
        status = nil
        # rubocop:disable Lint/HandleExceptions
        begin
          status = octo.merge_pull_request(rpo(org, repo), pr, commit)
        rescue StandardError
          # no-op
        end
        # rubocop:enable Lint/HandleExceptions
        status
      end
    end

    Lita.register_handler(GithubPR)
  end
end
