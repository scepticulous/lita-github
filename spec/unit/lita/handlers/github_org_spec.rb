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
  it { is_expected.to route_command('gh teams PagerDuty').to(:org_teams_list) }
  it { is_expected.to route_command('gh org teams GrapeDuty').to(:org_teams_list) }
  it { is_expected.to route_command('gh org team list GrapeDuty').to(:org_teams_list) }
  it { is_expected.to route_command('gh teams').to(:org_teams_list) }
  it { is_expected.to route_command('gh org teams').to(:org_teams_list) }
  it { is_expected.to route_command('gh org team list').to(:org_teams_list) }

  # org_team_add routing
  it { is_expected.to route_command('gh org team add GrapeDuty name:"All Staff" perms:pull').to(:org_team_add) }
  it { is_expected.to route_command('gh org team add name:"All Staff" perms:pull').to(:org_team_add) }

  # org_team_rm routing
  it { is_expected.to route_command('gh org team rm GrapeDuty ops').to(:org_team_rm) }
  it { is_expected.to route_command('gh org team rm GrapeDuty 42').to(:org_team_rm) }
  it { is_expected.to route_command('gh org team rm ops').to(:org_team_rm) }
  it { is_expected.to route_command('gh org team rm 42').to(:org_team_rm) }

  # org_user_add routing
  it { is_expected.to route_command('gh org user add GrapeDuty heckmantest theckman').to(:org_user_add) }
  it { is_expected.to route_command('gh org user add heckmantest theckman').to(:org_user_add) }
  it { is_expected.to route_command('gh org user add GrapeDuty 42 theckman').to(:org_user_add) }
  it { is_expected.to route_command('gh org user add 42 theckman').to(:org_user_add) }

  # org_user_rm routing
  it { is_expected.to route_command('gh org user rm GrapeDuty heckmantest theckman').to(:org_user_rm) }
  it { is_expected.to route_command('gh org user rm heckmantest theckman').to(:org_user_rm) }
  it { is_expected.to route_command('gh org user rm GrapeDuty 42 theckman').to(:org_user_rm) }
  it { is_expected.to route_command('gh org user rm 42 theckman').to(:org_user_rm) }

  # org_eject_user routing
  it { is_expected.to route_command('gh org eject GrapeDuty theckman').to(:org_eject_user) }
  it { is_expected.to route_command('gh org eject theckman').to(:org_eject_user) }

  let(:github_org) { Lita::Handlers::GithubOrg.new(robot) }
  let(:disabled_err) { 'Sorry, this function has either been disabled or not enabled in the config' }

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
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:config).and_return(conf_obj)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:octo).and_return(@octo_obj)
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
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:config).and_return(@conf_obj)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:octo).and_return(@octo_obj)
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
      before do
        allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(true)
      end

      it 'should return the method disabled error' do
        send_command('gh org team add GrapeDuty name:"HeckmanTest" perms:pull')
        expect(replies.last).to eql disabled_err
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
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:config).and_return(@conf_obj)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:octo).and_return(@octo_obj)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:team?).with('42').and_return(@team)
    end

    context 'when all goes well' do
      it 'should return the success message' do
        send_command('gh org team rm GrapeDuty 42')
        expect(replies.last).to eql "The 'HeckmanTest' team was deleted. Its ID was 42"
      end
    end

    context 'when the method is disabled' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(true)
      end

      it 'should return the method disabled error' do
        send_command('gh org team rm GrapeDuty 42')
        expect(replies.last).to eql disabled_err
      end
    end

    context 'when the team does not exist' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:team?).with('42').and_return(false)
      end

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

  describe '.org_eject_user' do
    before do
      @self_user = {
        name: 'OfficerURL',
        login: 'OfficerURL',
        id: 8_525_060
      }
      @t_user = {
        name: 'Tim Heckman',
        login: 'theckman',
        id: 787_332
      }
      @octo_obj = double('Octokit::Client', remove_organization_member: true)
      @conf_obj = double('Lita::Config', default_org: 'GrapeDuty')
      allow(@octo_obj).to receive(:user).with(no_args).and_return(@self_user)
      allow(@octo_obj).to receive(:user).with('theckman').and_return(@t_user)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:octo).and_return(@octo_obj)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:cofig).and_return(@conf_obj)
    end

    context 'when all goes well' do
      it 'should reply that the user was ejected' do
        send_command('gh org eject GrapeDuty theckman')
        expect(replies.last).to eql 'Ejected theckman out of GrapeDuty'
      end
    end

    context 'when the method is disabled' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(true)
      end

      it 'should return the method disabled error' do
        send_command('gh org eject GrapeDuty theckman')
        expect(replies.last).to eql disabled_err
      end
    end

    context 'when the user is the same user' do
      before { allow(@octo_obj).to receive(:user).with('OfficerURL').and_return(@self_user) }

      it 'should return the gtfo error message' do
        send_command('gh org eject GrapeDuty OfficerURL')
        expect(replies.last).to eql "No...\n\nಠ_ಠ"
      end
    end

    context 'when the user is not found' do
      before { allow(@octo_obj).to receive(:user).with('theckman').and_raise(Octokit::NotFound.new) }

      it 'should reply with the user not found message' do
        send_command('gh org eject GrapeDuty theckman')
        expect(replies.last).to eql 'Unable to find the GitHub user theckman'
      end
    end

    context 'when the Octokit client call bombs' do
      before { allow(@octo_obj).to receive(:remove_organization_member).and_raise(Octokit::NotFound.new) }

      it 'should return the *boom* error' do
        send_command('gh org eject GrapeDuty theckman')
        expect(replies.last).to eql 'I had a problem :( ... Octokit::NotFound'
      end
    end

    context 'when the action fails' do
      before { allow(@octo_obj).to receive(:remove_organization_member).and_return(false) }

      it 'should respond with the failure message' do
        send_command('gh org eject GrapeDuty theckman')
        expect(replies.last).to eql 'Failed to eject the user from the organization for an unknown reason'
      end
    end
  end

  describe '.org_user_add' do
    before do
      @self_user = {
        name: 'OfficerURL',
        login: 'OfficerURL',
        id: 8_525_060
      }
      @t_user = {
        name: 'Tim Heckman',
        login: 'theckman',
        id: 787_332
      }
      @team = {
        name: 'HeckmanTest',
        id: 42,
        slug: 'heckmantest'
      }
      @octo_obj = double('Octokit::Client', team: @team, add_team_membership: true)
      @conf_obj = double('Lita::Config', default_org: 'GrapeDuty')
      allow(@octo_obj).to receive(:user).with(no_args).and_return(@self_user)
      allow(@octo_obj).to receive(:user).with('theckman').and_return(@t_user)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:octo).and_return(@octo_obj)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:cofig).and_return(@conf_obj)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:team_id).and_return(42)
    end

    context 'when all goes well' do
      it 'should respond with a successful add' do
        send_command('gh org user add GrapeDuty heckmantest theckman')
        expect(replies.last).to eql "theckman has been added to the 'GrapeDuty/HeckmanTest' (heckmantest) team"
      end
    end

    context 'when the method is disabled' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(true)
      end

      it 'should return the method disabled error' do
        send_command('gh org user add GrapeDuty heckmantest theckman')
        expect(replies.last).to eql disabled_err
      end
    end

    context 'when the user is the same user' do
      before { allow(@octo_obj).to receive(:user).with('OfficerURL').and_return(@self_user) }

      it 'should return the gtfo error message' do
        send_command('gh org user add GrapeDuty heckmantest OfficerURL')
        expect(replies.last).to eql "No...\n\nಠ_ಠ"
      end
    end

    context 'when the user is not found' do
      before { allow(@octo_obj).to receive(:user).with('theckman').and_raise(Octokit::NotFound.new) }

      it 'should reply with the user not found message' do
        send_command('gh org user add GrapeDuty heckmantest theckman')
        expect(replies.last).to eql 'Unable to find the GitHub user theckman'
      end
    end

    context 'when the team is not found' do
      before { allow(@octo_obj).to receive(:team).with(42).and_raise(Octokit::NotFound.new) }

      it 'should reply with the team not found message' do
        send_command('gh org user add GrapeDuty heckmantest theckman')
        expect(replies.last).to eql 'Unable to match any teams based on: heckmantest'
      end
    end

    context 'when an error is hit adding the team membership' do
      before { allow(@octo_obj).to receive(:add_team_membership).with(42, 'theckman').and_raise(StandardError.new) }

      it 'should reply with the *boom* message' do
        send_command('gh org user add GrapeDuty heckmantest theckman')
        expect(replies.last).to eql 'I had a problem :( ... StandardError'
      end
    end
  end

  describe '.org_user_rm' do
    before do
      @self_user = {
        name: 'OfficerURL',
        login: 'OfficerURL',
        id: 8_525_060
      }
      @t_user = {
        name: 'Tim Heckman',
        login: 'theckman',
        id: 787_332
      }
      @team = {
        name: 'HeckmanTest',
        id: 42,
        slug: 'heckmantest'
      }
      @octo_obj = double('Octokit::Client', team: @team, remove_team_member: true)
      @conf_obj = double('Lita::Config', default_org: 'GrapeDuty')
      allow(@octo_obj).to receive(:user).with(no_args).and_return(@self_user)
      allow(@octo_obj).to receive(:user).with('theckman').and_return(@t_user)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:octo).and_return(@octo_obj)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:cofig).and_return(@conf_obj)
      allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:team_id).and_return(42)
    end

    context 'when all goes well' do
      it 'should respond with a successful removal' do
        send_command('gh org user rm GrapeDuty heckmantest theckman')
        expect(replies.last).to eql "theckman has been removed from the 'GrapeDuty/HeckmanTest' (heckmantest) team"
      end
    end

    context 'when the method is disabled' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubOrg).to receive(:func_disabled?).and_return(true)
      end

      it 'should return the method disabled error' do
        send_command('gh org user rm GrapeDuty heckmantest theckman')
        expect(replies.last).to eql disabled_err
      end
    end

    context 'when the user is the same user' do
      before { allow(@octo_obj).to receive(:user).with('OfficerURL').and_return(@self_user) }

      it 'should return the gtfo error message' do
        send_command('gh org user rm GrapeDuty heckmantest OfficerURL')
        expect(replies.last).to eql "No...\n\nಠ_ಠ"
      end
    end

    context 'when the user is not found' do
      before { allow(@octo_obj).to receive(:user).with('theckman').and_raise(Octokit::NotFound.new) }

      it 'should reply with the user not found message' do
        send_command('gh org user rm GrapeDuty heckmantest theckman')
        expect(replies.last).to eql 'Unable to find the GitHub user theckman'
      end
    end

    context 'when the team is not found' do
      before { allow(@octo_obj).to receive(:team).with(42).and_raise(Octokit::NotFound.new) }

      it 'should reply with the team not found message' do
        send_command('gh org user rm GrapeDuty heckmantest theckman')
        expect(replies.last).to eql 'Unable to match any teams based on: heckmantest'
      end
    end

    context 'when an error is hit adding the team membership' do
      before { allow(@octo_obj).to receive(:remove_team_member).with(42, 'theckman').and_raise(StandardError.new) }

      it 'should reply with the *boom* message' do
        send_command('gh org user rm GrapeDuty heckmantest theckman')
        expect(replies.last).to eql 'I had a problem :( ... StandardError'
      end
    end

    context 'when the Octokit method call succeeds, but GitHub fails to remove the user' do
      before { allow(@octo_obj).to receive(:remove_team_member).with(42, 'theckman').and_return(false) }

      it 'should reply with the failure message' do
        send_command('gh org user rm GrapeDuty heckmantest theckman')
        expect(replies.last).to eql "Failed to remove the user from the 'HeckmanTest' team for some unknown reason"
      end
    end
  end
end
