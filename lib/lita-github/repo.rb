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
  # Github handler common-use Repository methods
  module Repo
    PR_LIST_MAX_COUNT = 20

    def rpo(org, repo)
      "#{org}/#{repo}"
    end

    def repo?(r)
      octo.repository?(r)
    end

    def repo_match(response)
      md = response.match_data
      [organization(md['org']), md['repo']]
    end
  end
end
