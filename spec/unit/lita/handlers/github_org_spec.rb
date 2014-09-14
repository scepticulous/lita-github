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
  # org_team_list routing
  it { routes_command('gh teams PagerDuty').to(:org_teams_list) }
  it { routes_command('gh org teams GrapeDuty').to(:org_teams_list) }
  it { routes_command('gh org team list GrapeDuty').to(:org_teams_list) }
  it { routes_command('gh teams').to(:org_teams_list) }
  it { routes_command('gh org teams').to(:org_teams_list) }
  it { routes_command('gh org team list').to(:org_teams_list) }

  # org_team_add routing
  it { routes_command('gh org team add GrapeDuty name:"All Staff" perms:pull').to(:org_team_add) }
  it { routes_command('gh org team add name:"All Staff" perms:pull').to(:org_team_add) }

  let(:github_org) { Lita::Handlers::GithubOrg.new('robot') }

  ####
  # Helper Methods
  ####
  describe '.validate_team_add_opts' do
    context 'when opts are valid' do
      let(:opts) { { name: 'hi', perms: 'pull' } }

      it 'should return with happy Hash' do
        expect(github_org.send(:validate_team_add_opts, opts)).to eql success: true, msg: ''
      end
    end

    context 'when name is missing' do
      let(:opts) { { perms: 'pull' } }

      it 'should return a bad has with a proper message' do
        r = github_org.send(:validate_team_add_opts, opts)
        expect(r).to eql success: false, msg: "Missing the name option\n"
      end
    end

    context 'when perms is missing' do
      let(:opts) { { name: 'hi' } }

      it 'should return a bad has with a proper message' do
        r = github_org.send(:validate_team_add_opts, opts)
        expect(r).to eql success: false, msg: "Missing the perms option\n"
      end
    end

    context 'when perms is invalid' do
      let(:opts) { { name: 'hi', perms: 'something' } }

      it 'should return a bad has with a proper message' do
        r = github_org.send(:validate_team_add_opts, opts)
        expect(r).to eql(
          success: false, msg: "Valid perms are: pull push admin -- they can be selectively enabled via the config\n"
        )
      end
    end
  end

  describe '.permission_allowed?' do
    before do
      @perms = %w(pull push)
      @conf_obj = double('Lita::Config', org_team_add_allowed_perms: @perms)
      allow(github_org).to receive(:config).and_return(@conf_obj)
    end

    context 'always' do
      it 'should validate perm against the config' do
        expect(@perms).to receive(:include?).with('pull').and_call_original
        github_org.send(:permission_allowed?, 'pull')
      end
    end

    context 'when the permission is enabled' do
      it 'should return true' do
        expect(github_org.send(:permission_allowed?, 'pull')).to be_truthy
      end
    end

    context 'when the permission is not enabled' do
      it 'should return false' do
        expect(github_org.send(:permission_allowed?, 'admin')).to be_falsey
      end
    end
  end

  ####
  # Handlers
  ####
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
          "The organization 'GrapeDuty' was not found. Does my user have ownership perms?"
        )
      end
    end
  end

  describe '.org_team_add' do
    before do
      @team = { name: 'HeckmanTest', id: 42, slug: 'heckmantest', permission: 'pull' }
      @octo_obj = double('Octokit::Client', create_team: @team)
      @perms = %w(pull push)
      @conf_obj = double('Lita::Config', org_team_add_allowed_perms: @perms)
      allow(github_org).to receive(:config).and_return(@conf_obj)
      allow(github_org).to receive(:func_disabled?).and_return(false)
      allow(github_org).to receive(:octo).and_return(@octo_obj)
    end

    context 'when all goes well' do
      it 'should return that the team was created' do
        expect(@octo_obj).to receive(:create_team).with('GrapeDuty', name: 'HeckmanTest', permission: 'pull')
          .and_return(@team)
        send_command('gh org team add GrapeDuty name:"HeckmanTest" perms:pull')
        expect(replies.last).to eql "The 'HeckmanTest' team was created; Slug: heckmantest, ID: 42, Perms: pull"
      end
    end

    context 'when the method is disabled' do
      before { allow(github_org).to receive(:func_disabled?).and_return(true) }

      it 'should return the method disabled error' do
        send_command('gh org team add GrapeDuty name:"HeckmanTest" perms:pull')
        expect(replies.last).to eql 'Sorry, this function has either been disabled or not enabled in the config'
      end
    end

    context 'when all the options are missing' do
      it 'should respond with an error listing each one' do
        send_command('gh org team add GrapeDuty')
        expect(replies.last).to eql "Missing the name option
Missing the perms option
"
      end
    end

    context 'when the permission level is not a known one' do
      it 'should respond telling you the permission is unknown' do
        send_command('gh org team add GrapeDuty name:testing perms:something')
        expect(replies.last).to eql 'Valid perms are: pull push admin -- they can be ' \
                                    "selectively enabled via the config\n"
      end
    end

    context 'when the permission is now allowed in the config' do
      it 'should respond informing you of the permitted permissions' do
        send_command('gh org team add GrapeDuty name:testing perms:admin')
        expect(replies.last).to eql 'Sorry, the permission level you requested was not allowed in the '\
                                    'config. Right now the only perms permitted are: pull, push'
      end
    end

    context 'when the organization is not found' do
      before { allow(@octo_obj).to receive(:create_team).and_raise(Octokit::NotFound.new) }

      it 'should reply that the org was not found' do
        send_command('gh org team add GrapeDuty name:testing perms:pull')
        expect(replies.last).to eql "The organization 'GrapeDuty' was not found. Does my user have ownership perms?"
      end
    end
  end

  describe '.org_team_rm' do
    before do
      @team = { name: 'HeckmanTest', id: 42, slug: 'heckmantest', permission: 'pull' }
      @octo_obj = double('Octokit::Client', delete_team: true)
      allow(github_org).to receive(:config).and_return(@conf_obj)
      allow(github_org).to receive(:func_disabled?).and_return(false)
      allow(github_org).to receive(:octo).and_return(@octo_obj)
      allow(github_org).to receive(:team?).with('42').and_return(@team)
    end

    context 'when all goes well' do
      it 'should return the success message' do
        send_command('gh org team rm GrapeDuty 42')
        expect(replies.last).to eql "The 'HeckmanTest' team was deleted. Its ID was 42"
      end
    end

    context 'when the method is disabled' do
      before { allow(github_org).to receive(:func_disabled?).and_return(true) }

      it 'should return the method disabled error' do
        send_command('gh org team rm GrapeDuty 42')
        expect(replies.last).to eql 'Sorry, this function has either been disabled or not enabled in the config'
      end
    end

    context 'when the team does not exist' do
      before { allow(github_org).to receive(:team?).with('42').and_return(false) }

      it 'should respond with the team not found error' do
        send_command('gh org team rm GrapeDuty 42')
        expect(replies.last).to eql 'Unable to match any teams based on: 42'
      end
    end

    context 'when deletion fails' do
      before { allow(@octo_obj).to receive(:delete_team).and_return(false) }

      it 'should respond with the action failure message' do
        send_command('gh org team rm GrapeDuty 42')
        expect(replies.last).to eql "Something went wrong trying to delete the 'HeckmanTest' " \
                                    'team. Is Github having issues?'
      end
    end
  end
end
