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

require 'rotp'
require 'lita-github/version'
require 'lita-github/r'
require 'lita-github/config'
require 'lita-github/octo'

module Lita
  # Lita Handler
  module Handlers
    # GitHub Lita Handler
    class Github < Handler
      include LitaGithub::R       # Github handler common-use regex constants
      include LitaGithub::Config  # Github handler Lita configuration methods
      include LitaGithub::Octo    # Github handler common-use Octokit methods

      on :loaded, :setup_octo # from LitaGithub::Octo

      route(
        /#{LitaGithub::R::A_REG}status/, :status,
        command: true,
        help: {
          'github status' => 'get the system status from GitHub',
          'gh status' => 'get the system status from GitHub using short alias'
        }
      )

      route(
        /#{LitaGithub::R::A_REG}(?:v|version|build)/, :version,
        command: true,
        help: {
          'gh version' => 'get the lita-github version'
        }
      )

      route(
        /#{LitaGithub::R::A_REG}(?:token|2fa|tfa)/, :token_generate,
        command: true,
        help: {
          'gh token' => 'generate a Time-based One-Time Password (TOTP) using provided secret'
        }
      )

      route(
        /#{LitaGithub::R::A_REG}(?:whois|user)\s+(?<username>[a-zA-Z0-9_\-]+)/,
        :whois,
        command: true,
        help: {
          'gh whois theckman' => 'show some information about that GitHub user'
        }
      )

      # when setting default configuration values please remember one thing:
      # secure and safe by default
      config :access_token, default: nil
      config :default_team_slugs, default: nil
      config :repo_private_default, default: true
      config :org_team_add_allowed_perms, default: %w(pull)

      ####
      # Method Filters
      ####

      # Lita::Handlers::Github
      config :totp_secret, default: nil

      # Lita::Handlers::GithubRepo
      config :repo_create_enabled, default: true
      config :repo_rename_enabled, default: true
      config :repo_delete_enabled, default: false
      config :repo_team_add_enabled, default: false
      config :repo_team_rm_enabled, default: false
      config :repo_update_description_enabled, default: true
      config :repo_update_homepage_enabled, default: true

      # Lita::Handlers::GithubPR
      config :pr_merge_enabled, default: true

      # Lita::Handlers::GithubOrg
      config :default_org, default: nil
      config :org_team_add_enabled, default: false
      config :org_team_rm_enabled, default: false
      config :org_user_add_enabled, default: false
      config :org_user_rm_enabled, default: false
      config :org_eject_user_enabled, default: false

      def status(response)
        status = octo.github_status_last_message
        response.reply(t("status.#{status[:status]}", status.to_h))
      end

      def version(response)
        response.reply("lita-github v#{LitaGithub::VERSION}")
      end

      def token_generate(response)
        if config.totp_secret.is_a?(String)
          response.reply(t('token_generate.totp', token: ROTP::TOTP.new(config.totp_secret).now))
        else
          response.reply(t('token_generate.no_secret'))
        end
      end

      def whois(response)
        username = response.match_data['username'].strip

        begin
          user = octo.user(username)
        rescue Octokit::NotFound
          return response.reply(t('whois.user_not_found', username: username))
        end

        orgs = octo.organizations(username).map { |o| o[:login] }
        reply = whois_reply(user, orgs)

        response.reply(reply)
      end

      private

      def key_valid?(val)
        (val.nil? || val.empty?) ? false : true
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def whois_reply(user, orgs)
        name = user.key?(:name) && !user[:name].nil? ? " (#{user[:name]})" : ''

        reply = "#{user[:login]}#{name} :: #{user[:html_url]}\n"

        reply << t('whois.location', l: user[:location]) if key_valid?(user[:location])
        reply << t('whois.company', c: user[:company]) if key_valid?(user[:company])
        reply << t('whois.orgs', o: orgs.join(', ')) unless orgs.empty?

        reply << t('whois.id', i: user[:id])
        key_valid?(user[:email]) ? reply << ", #{t('whois.email', e: user[:email])}\n" : reply << "\n"

        reply << t('whois.account_info', user.to_h)
        reply << t('whois.user_info', user.to_h)
        reply
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end

    Lita.register_handler(Github)
  end
end
