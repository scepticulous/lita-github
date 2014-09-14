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

module LitaGithub
  # Github handler common-use methods
  #
  # @author Tim Heckman <tim@pagerduty.com>
  module General
    # Parse the options in the command using the standard option regex
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @param cmd [String] the full command line provided to Lita
    # @return [Hash] the key:value pairs that were in the command string
    def opts_parse(cmd)
      o = {}
      cmd.scan(LitaGithub::R::OPT_REGEX).flatten.each do |opt|
        k, v = opt.strip.split(':')
        k = k.to_sym
        o[k] = v unless o.key?(k)
      end
      o
    end

    # Parse the options in the command using the extended option regex
    #
    # @author Tim Heckman <tim@pagerduty.com>
    # @param cmd [String] the full command line provided to Lita
    # @return [Hash] the key:value pairs that were in the command string
    def e_opts_parse(cmd)
      o = {}
      cmd.scan(LitaGithub::R::E_OPT_REGEX).flatten.each do |opt|
        k, v = opt.strip.split(':')
        k = k.to_sym

        # if it looks like we're using the extended option (first character is a " or '):
        #   slice off the first and last character of the string
        # otherwise:
        #   do nothing
        v = v.slice!(1, (v.length - 2)) if %w(' ").include?(v.slice(0))

        o[k] = v unless o.key?(k)
      end
      o
    end
  end
end
