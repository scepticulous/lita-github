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

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'lita-github/version'

Gem::Specification.new do |s|
  s.name        = 'lita-github'
  s.summary     = 'GitHub repo/org management in Lita; handler not ready for production'
  s.author      = 'Tim Heckman'
  s.email       = 'tim@pagerduty.com'
  s.license     = 'Apache 2.0'
  s.version     = LitaGithub::VERSION
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.homepage    = 'https://github.com/PagerDuty/lita-github'
  s.description = 'Lita handler for managing your GitHub account/organization; handler not ready for production'

  s.test_files  = `git ls-files spec/*`.split
  s.files       = `git ls-files`.split

  s.required_ruby_version = '>= 2.1.0'
  s.metadata              = { 'lita_plugin_type' => 'handler' }

  s.add_development_dependency 'bundler', '~> 1.5'
  s.add_development_dependency 'rake', '~> 10.2'
  s.add_development_dependency 'rubocop', '~> 0.28.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'fuubar', '~> 2.0'
  s.add_development_dependency 'pry', '~> 0.10', '>= 0.10.1'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.4', '>= 0.4.0'
  s.add_development_dependency 'yard', '~> 0.8.7'

  s.add_runtime_dependency 'lita', '~> 4.0'
  s.add_runtime_dependency 'octokit', '~> 3.3'
  s.add_runtime_dependency 'rotp', '~> 2.0'
  s.add_runtime_dependency 'lita-confirmation'
end
