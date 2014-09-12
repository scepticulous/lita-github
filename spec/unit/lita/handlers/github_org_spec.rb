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

describe Lita::Handlers::GithubOrg, lita_handler: true do
  it { routes_command('gh teams PagerDuty').to(:org_teams_list) }
  it { routes_command('gh org teams GrapeDuty').to(:org_teams_list) }
  it { routes_command('gh org team list PagerDuty').to(:org_teams_list) }
  it { routes_command('gh teams').to(:org_teams_list) }
  it { routes_command('gh org teams').to(:org_teams_list) }
  it { routes_command('gh org team list').to(:org_teams_list) }

  let(:github_org) { Lita::Handlers::GithubOrg.new('robot') }

  describe '.org_teams_list' do
    before do
      @teams = [
        { name: 'Owners', id: 1, slug: 'owners', permission: 'admin' },
        { name: 'HeckmanTest', slug: 'heckmantest', id: 42, permission: 'push' },
        { name: 'A Team', slug: 'a-team', id: 84, permission: 'pull' }
      ]
      conf_obj = double('Lita::Configuration', default_org: 'GrapeDuty')
      @octo_obj = double('Octokit::Client', organization_teams: @teams)
      allow(github_org).to receive(:config).and_return(conf_obj)
      allow(github_org).to receive(:octo).and_return(@octo_obj)
    end

    context 'when provided a valid org' do
      it 'should return a list of the team sorted, with Owners at the top' do
        expect(@octo_obj).to receive(:organization_teams).with('GrapeDuty').and_return(@teams)
        send_command('gh teams GrapeDuty')
        expect(replies.last).to eql 'Showing 3 team(s) for GrapeDuty:
Name: Owners, Slug: owners, ID: 1, Perms: admin
Name: A Team, Slug: a-team, ID: 84, Perms: pull
Name: HeckmanTest, Slug: heckmantest, ID: 42, Perms: push
'
      end
    end

    context 'when provided an invalid org' do
      before { allow(@octo_obj).to receive(:organization_teams).and_raise(Octokit::NotFound.new) }

      it 'should return a message indicating it could not find the organization' do
        send_command('gh teams GrapeDuty')
        expect(replies.last).to eql(
          "The organization 'GrapeDuty' was not found. Does my user have ownership permission?"
        )
      end
    end
  end
end
