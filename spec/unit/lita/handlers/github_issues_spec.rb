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

require 'spec_helper'

describe Lita::Handlers::GithubIssues, lita_handler: true do
  # issues_list command routing
  it { is_expected.to route_command('gh issues GrapeDuty/lita-test').to(:issues_list) }
  it { is_expected.to route_command('gh issues lita-test').to(:issues_list) }
  it { is_expected.to route_command('gh issues lita-test key:value keys:"values"').to(:issues_list) }
  it { is_expected.to route_command('gh repo issues GrapeDuty/lita-test').to(:issues_list) }
  it { is_expected.to route_command('gh repo issues lita-test').to(:issues_list) }
  it { is_expected.to route_command('gh repo issues lita-test key:value keys:"values"').to(:issues_list) }

  let(:gh_org) { 'GapeDuty' }
  let(:gh_repo) { 'lita-test' }
  let(:github_issues) { Lita::Handlers::GithubIssues.new('robot') }

  describe '.validate_list_opts' do
    let(:good_opts) { { state: 'open', sort: 'updated', direction: 'asc' } }
    let(:bad_opts) { Hash.new('sometestval').merge(state: 'shipped', sort: 'most code', direction: 'backwards, yo') }
    let(:bad_state) { good_opts.merge(state: 'something') }
    let(:bad_sort) { good_opts.merge(sort: 'something') }
    let(:bad_direction) { good_opts.merge(direction: 'backwards, yo') }
    let(:io_header) { "Invalid option(s):\n" }

    context 'when all options are good' do
      it 'should reply with a string' do
        expect(github_issues.send(:validate_list_opts, good_opts)).to be_an_instance_of String
      end

      it 'should reply with empty string' do
        expect(github_issues.send(:validate_list_opts, good_opts)).to be_empty
      end
    end

    context 'when :state is invalid' do
      it 'should return a string containing a valid error message' do
        r =  github_issues.send(:validate_list_opts, bad_state)
        expect(r).to eql "#{io_header}Issues can be one of the following states: 'open', 'closed', or 'all'\n"
      end
    end

    context 'when :sort is invalid' do
      it 'should return a string containing a valid error message' do
        r =  github_issues.send(:validate_list_opts, bad_sort)
        expect(r).to eql "#{io_header}Issues can be sorted by one of the following: 'created', 'updated', 'comments'\n"
      end
    end

    context 'when :direction is invalid' do
      it 'should return a string containing a valid error message' do
        r =  github_issues.send(:validate_list_opts, bad_direction)
        expect(r).to eql "#{io_header}Issues can be ordered either 'asc' (ascending) or 'desc' (descending)\n"
      end
    end

    context 'when the user did EVERYTHING wrong' do
      it 'should return a string containing all the error messages' do
        r =  github_issues.send(:validate_list_opts, bad_opts)
        expect(r).to eql(
          "#{io_header}Issues can be one of the following states: 'open', 'closed', or 'all'\n" \
          "Issues can be sorted by one of the following: 'created', 'updated', 'comments'\n" \
          "Issues can be ordered either 'asc' (ascending) or 'desc' (descending)\n"
        )
      end
    end
  end

  describe '.issues_list' do
    before do
      issues = [
        {
          number: 42, title: 'XYXYXYXY', html_url: 'https://github.com/GrapeDuty/lita-test/issues/42',
          user: { login: 'theckman' }
        },
        {
          number: 84, title: 'YZYZYZYZ', html_url: 'https://github.com/GrapeDuty/lita-test/issues/84',
          user: { login: 'theckman' }
        },
        {
          number: 99, title: 'NO', html_url: 'https://github.com/GrapeDuty/lita-test/issues/99',
          user: { login: 'theckman' }, pull_request: {}
        }
      ]
      @octo_obj = double('Octokit::Client', list_issues: issues)
      allow(github_issues).to receive(:octo).and_return(@octo_obj)
      allow(github_issues).to receive(:repo?).and_return(true)
      allow(github_issues).to receive(:validate_list_opts).and_return('')
    end

    context 'when all goes well' do
      it 'should reply with the list of issues' do
        send_command('gh issues GrapeDuty/lita-test')
        r = replies.last
        expect(r).to eql "Showing 2 issue(s) for GrapeDuty/lita-test
GrapeDuty/lita-test #42: 'XYXYXYXY' opened by theckman :: https://github.com/GrapeDuty/lita-test/issues/42
GrapeDuty/lita-test #84: 'YZYZYZYZ' opened by theckman :: https://github.com/GrapeDuty/lita-test/issues/84
"
      end
    end

    context 'when there are no issues' do
      before { allow(@octo_obj).to receive(:list_issues).and_return([]) }

      it 'should return message indicating no issues' do
        send_command('gh issues GrapeDuty/lita-test')
        expect(replies.last).to eql 'There are no open issues for GrapeDuty/lita-test'
      end
    end

    context 'when there is an option that fails validation' do
      before { allow(github_issues).to receive(:validate_list_opts).and_return('sadpanda') }

      it 'should reply with the response from .validate_list_opts' do
        send_command('gh issues GrapeDuty/lita-test')
        expect(replies.last).to eql 'sadpanda'
      end
    end

    context 'when the repo is not found' do
      before { allow(github_issues).to receive(:repo?).and_return(false) }

      it 'should reply with response indicating repo not found' do
        send_command('gh issues GrapeDuty/lita-test')
        expect(replies.last).to eql 'That repo (GrapeDuty/lita-test) was not found'
      end
    end

    context 'when an option passes validation, but fails from GitHub' do
      before { allow(@octo_obj).to receive(:list_issues).and_raise(Octokit::UnprocessableEntity.new) }

      it 'should reply indicating an issue was hit and include the exception message' do
        send_command('gh issues GrapeDuty/lita-test')
        expect(replies.last).to eql "An invalid option was provided, here's the error from Octokit:
Octokit::UnprocessableEntity"
      end
    end

    context 'when there is a general error when calling GitHub' do
      before { allow(@octo_obj).to receive(:list_issues).and_raise(StandardError.new) }

      it 'should reply indicating an issue was hit and include the exception message' do
        send_command('gh issues GrapeDuty/lita-test')
        expect(replies.last).to eql 'I had a problem :( ... StandardError'
      end
    end
  end
end
