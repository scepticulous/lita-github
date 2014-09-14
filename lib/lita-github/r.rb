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
  # Github handler common-use regex constants
  module R
    # command alias regex (!gh or !github for example)
    A_REG     ||= '(?:gh|github)\s+?'

    # option regex, letting you scan the command string of things like:
    # key1:value key2:value, etc.
    OPT_REGEX ||= /((?:\s+?[a-zA-Z0-9_]+?):(?:[a-zA-Z0-9_]+))/

    # extended option regex, letting you scan the string for things like:
    #  key1:value key2:"value2" key3:'a better value'
    E_OPT_REGEX ||= /((?:\s+?[a-zA-Z0-9_]+?):(?:(?:".+?")|(?:'.+?')|(?:[a-zA-Z0-9_]+)))/

    # regex matcher for: Org/repo
    REPO_REGEX = '(?:(?<org>[a-zA-Z0-9_\-]+)(?:\s+?)?\/)?(?:\s+?)?(?<repo>[a-zA-Z0-9_\-]+)'
  end
end
