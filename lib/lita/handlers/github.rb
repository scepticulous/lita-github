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

      def self.default_config(config)
        # when setting default configuration values please remember one thing:
        # secure and safe by default
        config.default_team_slug    = nil
        config.repo_private_default = true

        ####
        # Method Filters
        ####

        # Lita::Handlers::Github
        config.totp_secret = nil

        # Lita::Handlers::GithubRepo
        config.repo_create_enabled              = true
        config.repo_delete_enabled              = false
        config.repo_team_add_enabled            = false
        config.repo_team_rm_enabled             = false
        config.repo_update_description_enabled  = true
        config.repo_update_homepage_enabled     = true

        # Lita::Handlers::GithubPR
        config.pr_merge_enabled = true

        # Lita::Handlers::GithubOrg
        config.org_team_add_enabled       = false
        config.org_team_rm_enabled        = false
        config.org_team_add_allowed_perms = %w(pull)
      end

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
    end

    Lita.register_handler(Github)
  end
end
