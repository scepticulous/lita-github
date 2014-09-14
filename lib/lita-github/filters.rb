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
  # Github handler common-use method filters
  #
  # @author Tim Heckman <tim@pagerduty.com>
  module Filters
    # Returns whether or not the function has been disabled in the config
    #
    # @param method [String] the method name, usually just __method__
    # @return [TrueClass] if function is disabled
    # @return [FalseClass] if function is disabled
    def func_disabled?(method)
      config.send("#{method}_enabled".to_sym) ? false : true
    end
  end
end
