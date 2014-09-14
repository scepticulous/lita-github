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

require 'octokit'

module LitaGithub
  # Github handler common-use Octokit methods
  #
  # @author Tim Heckman <tim@pagerduty.com>
  module Octo
    # Accessor method for the Github access token in the config
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @return [String] the Github API access token
    def access_token
      config.access_token
    end

    # To be used to set up Octokit::Client when loading the Handler class
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @return [NilClass]
    def setup_octo(_)
      @@octo ||= Octokit::Client.new(access_token: access_token)
      @@octo.auto_paginate = true
      nil
    end

    # Object access method for Octokit client
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @return [Octokit::Client]
    # @example
    #  octo.create_team('PagerDuty', name: 'Example Group', perms:pull)
    def octo
      @@octo
    end
  end
end
