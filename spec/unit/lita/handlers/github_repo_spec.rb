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

describe Lita::Handlers::GithubRepo, lita_handler: true do
  # repo_create command routing
  it { is_expected.to route_command('gh repo create GrapeDuty/lita-test').to(:repo_create) }
  it { is_expected.to route_command('gh repo new GrapeDuty/lita-test').to(:repo_create) }
  it { is_expected.to route_command('gh repo new lita-test').to(:repo_create) }
  it { is_expected.to route_command('gh repo new GrapeDuty/lita-test private:true team:heckman').to(:repo_create) }
  it { is_expected.to route_command('gh repo new GrapeDuty/lita-test private:true randomunparseabletext ').to(:repo_create) }

  # repo_rename command routing
  it { is_expected.to route_command('gh repo rename GrapeDuty/lita-test lita-test-2').to(:repo_rename) }
  it { is_expected.to route_command('gh repo rename lita-test lita-test-2').to(:repo_rename) }

  # repo_delete command routing
  it { is_expected.to route_command('gh repo delete GrapeDuty/lita-test').to(:repo_delete) }
  it { is_expected.to route_command('gh repo delete lita-test').to(:repo_delete) }

  # repo_info command routing
  it { is_expected.to route_command('gh repo info GrapeDuty/lita-test').to(:repo_info) }
  it { is_expected.to route_command('gh repo info lita-test').to(:repo_info) }

  # repo_teams_list routing
  it { is_expected.to route_command('gh repo teams GrapeDuty/lita-test').to(:repo_teams_list) }
  it { is_expected.to route_command('gh repo team list GrapeDuty/lita-test').to(:repo_teams_list) }
  it { is_expected.to route_command('gh repo teams lita-test').to(:repo_teams_list) }
  it { is_expected.to route_command('gh repo team list lita-test').to(:repo_teams_list) }

  # repo_team_router routing
  it { is_expected.to route_command('gh repo team add everyone GrapeDuty/lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team add everyone to GrapeDuty/lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team add everyone lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team add everyone to lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team add 42 GrapeDuty/lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team add 42 to GrapeDuty/lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team add 42 lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team add 42 to lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm everyone GrapeDuty/lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm everyone to GrapeDuty/lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm everyone from GrapeDuty/lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm everyone lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm everyone to lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm everyone from lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm 42 GrapeDuty/lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm 42 to GrapeDuty/lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm 42 lita-test').to(:repo_team_router) }
  it { is_expected.to route_command('gh repo team rm 42 to lita-test').to(:repo_team_router) }

  # repo_update_router routing
  it do
    is_expected.to route_command(
      'gh repo update homepage GrapeDuty/lita-test https://github.com/GrapeDuty/lita-test'
    ).to(:repo_update_router)
  end
  it do
    is_expected.to route_command(
      'gh repo update homepage lita-test https://github.com/GrapeDuty/lita-test'
    ).to(:repo_update_router)
  end
  it { is_expected.to route_command('gh repo update description GrapeDuty/lita-test Some description here').to(:repo_update_router) }
  it { is_expected.to route_command('gh repo update description lita-test Some description here').to(:repo_update_router) }

  let(:github_repo) { Lita::Handlers::GithubRepo.new(robot) }
  let(:github_org) { 'GrapeDuty' }
  let(:disabled_reply) { 'Sorry, this function has either been disabled or not enabled in the config' }

  ####
  # Helper Methods
  ####
  describe '.privacy_decider' do
    before do
      c_obj = double('Lita::Configuration', repo_private_default: :dummyvalue)
      allow(github_repo).to receive(:config).and_return(c_obj)
    end

    it 'should return true when value is "true"' do
      expect(github_repo.send(:privacy_decider, 'true')).to be_truthy
    end

    it 'should return true when value is "True"' do
      expect(github_repo.send(:privacy_decider, 'True')).to be_truthy
    end

    it 'should return false when value is "false"' do
      expect(github_repo.send(:privacy_decider, 'false')).to be_falsey
    end

    it 'should return the default when the value is something unknown' do
      expect(github_repo.send(:privacy_decider, 'something')).to eql :dummyvalue
    end
  end

  describe '.should_repo_be_private?' do
    before do
      @c_obj = double('Lita::Configuration', repo_private_default: true)
      allow(github_repo).to receive(:config).and_return(@c_obj)
    end

    it 'should return the default if value nil' do
      expect(@c_obj).to receive(:repo_private_default).and_return(:dummyvalue)
      expect(github_repo.send(:should_repo_be_private?, nil)).to eql :dummyvalue
    end

    it 'should return the default if value empty string ("")' do
      expect(@c_obj).to receive(:repo_private_default).and_return(:dummyvalue)
      expect(github_repo.send(:should_repo_be_private?, '')).to eql :dummyvalue
    end

    it 'should call privacy_decider() with the value if not nil or empty' do
      expect(github_repo).to receive(:privacy_decider).with('ohai').and_return(:dummyvalue)
      expect(github_repo.send(:should_repo_be_private?, 'ohai')).to eql :dummyvalue
    end
  end

  describe '.default_teams' do
    before do
      allow(github_repo).to receive(:team_id_by_slug).and_return(88)
    end

    context 'when default_team_slugs is set' do
      before do
        cfg_obj = double('Lita::Configuration', default_team_slugs: ['heckman'])
        allow(github_repo).to receive(:config).and_return(cfg_obj)
      end

      it 'should return an array containing the team ID of the slug' do
        expect(github_repo).to receive(:team_id_by_slug).with('heckman', 'GrapeDuty')
          .and_return(42)
        expect(github_repo.send(:default_teams, github_org)).to eql [42]
      end
    end

    context 'when default_team_slugs is not set' do
      before do
        cfg_obj = double('Lita::Configuration', default_team_slugs: nil)
        allow(github_repo).to receive(:config).and_return(cfg_obj)
      end

      it 'should return [nil]' do
        expect(github_repo.send(:default_teams, github_org)).to eql [nil]
      end
    end

    context 'when default_team_slugs is an empty array' do
      before do
        cfg_obj = double('Lita::Configuration', default_team_slugs: [])
        allow(github_repo).to receive(:config).and_return(cfg_obj)
      end

      it 'should return [nil]' do
        expect(github_repo.send(:default_teams, github_org)).to eql [nil]
      end
    end

    context 'when default_team_slugs is set to an array with multiple elements' do
      before do
        cfg_obj = double('Lita::Configuration', default_team_slugs: %w(heckman orwell))
        allow(github_repo).to receive(:config).and_return(cfg_obj)
      end

      it 'should return an array containing the corresponding team IDs' do
        expect(github_repo).to receive(:team_id_by_slug).with('heckman', 'GrapeDuty')
          .and_return(42)
        expect(github_repo).to receive(:team_id_by_slug).with('orwell', 'GrapeDuty')
          .and_return(84)
        expect(github_repo.send(:default_teams, github_org)).to eql [42, 84]
      end
    end
  end

  describe '.extrapolate_create_opts' do
    context 'when default_team_slugs is set' do
      before do
        @eco_opts = {}
        @c_obj = double('Lita::Configuration', default_team_slugs: ['h3ckman'])
        allow(github_repo).to receive(:config).and_return(@c_obj)
        allow(github_repo).to receive(:team_id_by_slug).and_return(42)
        allow(github_repo).to receive(:should_repo_be_private?).and_return(true)
      end

      it 'should set the :organization key, :team_id key, and :private key' do
        h = { organization: github_org, team_id: 42, private: true }
        expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
      end

      it 'should set the private key to the return of should_repo_be_private?' do
        opts = { private: 'test', team_id: 42 }
        expect(github_repo).to receive(:should_repo_be_private?).with('test').and_return :ohai
        r = github_repo.send(:extrapolate_create_opts, opts, github_org)
        expect(r[:private]).to eql :ohai
      end

      context 'when there is no :team set' do
        context 'when default_teams returns an array containing a team id' do
          it 'should get the default team_id' do
            h = { organization: github_org, team_id: 44, private: true }
            expect(github_repo).to receive(:default_teams).with(github_org).and_return([44])
            expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
          end
        end

        context 'when default_teams returns [nil]' do
          before do
            @c_obj = double('Lita::Configuration', default_team_slugs: nil)
            allow(github_repo).to receive(:config).and_return(@c_obj)
          end

          it 'should not set the :team_id key' do
            h = { organization: github_org, private: true }
            expect(github_repo).to receive(:default_teams).with(github_org).and_return([nil])
            expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
          end
        end
      end

      context 'when options contains :team and no :team_id' do
        context 'when given a valid slug' do
          before { @eco_opts = { team: 'heckman' } }

          it 'should set the :team_id key' do
            h = { organization: github_org, team_id: 84, private: true }.merge!(@eco_opts)
            expect(github_repo).to receive(:team_id_by_slug).with('heckman', github_org).and_return(84)
            expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
          end
        end

        context 'when given an invalid slug' do
          context 'when there is a default slug set' do
            it 'should set the team to the default' do
              h = { organization: github_org, team_id: 42, private: true }.merge!(@eco_opts)
              expect(github_repo).to receive(:team_id_by_slug).with('h3ckman', github_org).and_return(42)
              expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
            end
          end

          context 'when there is no default slug set' do
            before do
              @eco_opts = { team: 'h3ckman', private: true }
              c_obj = double('Lita::Configuration', default_team_slugs: nil)
              allow(github_repo).to receive(:config).and_return(c_obj)
            end

            it 'should not set a :team_id' do
              h = { organization: github_org }.merge!(@eco_opts)
              expect(github_repo).to receive(:team_id_by_slug).with('h3ckman', github_org)
                .and_return(nil)
              expect(github_repo).to receive(:default_teams).with(github_org).and_call_original
              expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
            end
          end
        end
      end

      context 'when there is a :team_id key' do
        before { @eco_opts = { team_id: 44, private: true } }

        it 'should just leave it alone...' do
          h = { organization: github_org }.merge!(@eco_opts)
          expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
        end
      end
    end

    context 'with an array of default teams' do
      before do
        allow(github_repo).to receive(:should_repo_be_private?).and_return(true)
      end

      context 'consisting of a nil element' do
        before do
          allow(github_repo).to receive(:default_teams).with(github_org).and_return([nil])
        end

        it 'does not set :team_id' do
          expect(github_repo.send(:extrapolate_create_opts, { private: true }, github_org)).to eql(organization: github_org, private: true)
        end
      end

      context 'consisting of one valid team ID' do
        before do
          allow(github_repo).to receive(:default_teams).with(github_org).and_return([42])
        end

        it 'sets :team_id' do
          expect(github_repo.send(:extrapolate_create_opts, { private: true }, github_org)).to eql(organization: github_org, team_id: 42, private: true)
        end
      end

      context 'consisting of two valid team IDs' do
        before do
          allow(github_repo).to receive(:default_teams).with(github_org).and_return([42, 84])
        end

        it 'sets :team_id and :other_teams' do
          expect(github_repo.send(:extrapolate_create_opts, { private: true }, github_org)).to eql(organization: github_org, team_id: 42, other_teams: [84], private: true)
        end
      end

      context 'consisting of three valid team IDs' do
        before do
          allow(github_repo).to receive(:default_teams).with(github_org).and_return([42, 84, 1])
        end

        it 'sets :team_id and :other_teams' do
          expect(github_repo.send(:extrapolate_create_opts, { private: true }, github_org)).to eql(organization: github_org, team_id: 42, other_teams: [84, 1], private: true)
        end
      end

      context 'consisting of one valid team ID and one invalid team ID' do
        before do
          allow(github_repo).to receive(:default_teams).with(github_org).and_return([42, nil])
        end

        it 'sets :team_id but not :other_teams' do
          expect(github_repo.send(:extrapolate_create_opts, { private: true }, github_org)).to eql(organization: github_org, team_id: 42, private: true)
        end
      end
    end
  end

  describe '.create_repo' do
    before do
      client = double('Octokit::Client', create_repository: nil)
      allow(github_repo).to receive(:octo).and_return(client)
      allow(client).to receive(:team).exactly(2).times.and_return({ id: 42, name: 'heckman' }, { id: 84, name: 'orwell' })
    end

    context 'when repo created' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(true)
      end

      it 'should confirm successful creation' do
        opts = { private: true, team_id: 42, organization: github_org }
        expect(github_repo.send(:create_repo, github_org, 'lita-test', opts))
          .to eql 'Created GrapeDuty/lita-test: https://github.com/GrapeDuty/lita-test'
      end

      context 'when other teams are given' do
        it 'should add teams to the repo after creating it' do
          expect(github_repo).to receive(:add_team_to_repo).with('GrapeDuty/lita-test', { id: 42, name: 'heckman' })
          expect(github_repo).to receive(:add_team_to_repo).with('GrapeDuty/lita-test', { id: 84, name: 'orwell' })
          opts = { private: true, team_id: 1, other_teams: [42, 84], organization: github_org }
          expect(github_repo.send(:create_repo, github_org, 'lita-test', opts))
            .to eql 'Created GrapeDuty/lita-test: https://github.com/GrapeDuty/lita-test'
        end
      end
    end

    context 'when repo not created' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(false)
      end

      it 'should confirm failure' do
        opts = { private: true, team_id: 42, organization: github_org }
        expect(github_repo.send(:create_repo, github_org, 'lita-test', opts))
          .to eql 'Unable to create GrapeDuty/lita-test'
      end
    end
  end

  describe '.delete_repo' do
    before do
      allow(github_repo).to receive(:octo).and_return(double('Octokit::Client', delete_repository: nil))
    end

    context 'when repo deleted' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(false)
      end

      it 'should confirm successful delete' do
        expect(github_repo.send(:delete_repo, github_org, 'lita-test'))
          .to eql 'Deleted GrapeDuty/lita-test'
      end
    end

    context 'when repo not deleted' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(true)
      end

      it 'should reply with failure message' do
        expect(github_repo.send(:delete_repo, github_org, 'lita-test'))
          .to eql 'Unable to delete GrapeDuty/lita-test'
      end
    end
  end

  describe '.rename_repo' do
    before do
      allow(github_repo).to receive(:octo).and_return(double('Octokit::Client', edit_repository: nil))
    end

    context 'when repo renamed' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/better-lita-test").and_return(true)
      end

      it 'should confirm successful rename' do
        expect(github_repo.send(:rename_repo, github_org, 'lita-test', 'better-lita-test'))
          .to eql 'Renamed GrapeDuty/lita-test to GrapeDuty/better-lita-test'
      end
    end

    context 'when repo not renamed' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/better-lita-test").and_return(false)
      end

      it 'should reply with failure message' do
        expect(github_repo.send(:rename_repo, github_org, 'lita-test', 'better-lita-test'))
          .to eql 'Unable to rename GrapeDuty/lita-test'
      end
    end
  end

  describe '.remove_team_from_repo' do
    before do
      @octo_obj = double('Octokit::Client', remove_team_repository: true)
      allow(github_repo).to receive(:octo).and_return(@octo_obj)
    end

    context 'when it succeeds' do
      it 'should reply with the success message' do
        expect(@octo_obj).to receive(:remove_team_repository).with(42, 'GrapeDuty/lita-test')
          .and_return(true)
        r = github_repo.send(:remove_team_from_repo, 'GrapeDuty/lita-test', id: 42, name: 'HeckmanTest')
        expect(r).to eql "Removed the 'HeckmanTest' team from GrapeDuty/lita-test"
      end
    end

    context 'when it fails' do
      before { allow(@octo_obj).to receive(:remove_team_repository).and_return(false) }

      it 'should reply with the failure message' do
        r = github_repo.send(:remove_team_from_repo, 'GrapeDuty/lita-test', id: 42, name: 'HeckTest')
        expect(r).to eql "Something went wrong trying to remove the 'HeckTest' team from GrapeDuty/lita-test"
      end
    end
  end

  describe '.add_team_to_repo' do
    before do
      @octo_obj = double('Octokit::Client', add_team_repository: true)
      allow(github_repo).to receive(:octo).and_return(@octo_obj)
    end

    context 'when it succeeds' do
      it 'should reply with the success message' do
        expect(@octo_obj).to receive(:add_team_repository).with(42, 'GrapeDuty/lita-test')
          .and_return(true)
        r = github_repo.send(:add_team_to_repo, 'GrapeDuty/lita-test', id: 42, name: 'HeckmanTest')
        expect(r).to eql "Added the 'HeckmanTest' team to GrapeDuty/lita-test"
      end
    end

    context 'when it fails' do
      before { allow(@octo_obj).to receive(:add_team_repository).and_return(false) }

      it 'should reply with the failure message' do
        r = github_repo.send(:add_team_to_repo, 'GrapeDuty/lita-test', id: 42, name: 'HeckTest')
        expect(r).to eql(
          "Something went wrong trying to add the 'HeckTest' team to GrapeDuty/lita-test. " \
            'Is that team in your organization?'
        )
      end
    end
  end

  describe '.gh_team' do
    before do
      @team1 = { name: 'HeckTest', id: 42 }
      @team2 = { name: 'Heckman', id: 84 }
      @octo_obj = double('Octokit::Client', team: {})
      allow(github_repo).to receive(:octo).and_return(@octo_obj)
      allow(github_repo).to receive(:team_id_by_slug).with('Heckman', 'GrapeDuty').and_return(@team2[:id])
    end

    context 'when the team provided is the team id' do
      before { allow(@octo_obj).to receive(:team).with(42).and_return(@team1) }

      it 'should return the specific team' do
        expect(github_repo.send(:gh_team, 'GrapeDuty', 42)).to eql @team1
      end
    end

    context 'when the team provided is the team' do
      before { allow(@octo_obj).to receive(:team).with(84).and_return(@team2) }

      it 'should return the specific team' do
        expect(github_repo.send(:gh_team, 'GrapeDuty', 'Heckman')).to eql @team2
      end
    end

    context 'when the team was not found' do
      context 'but it found the id by the slug' do
        before do
          allow(github_repo).to receive(:team_id_by_slug).with('Wtf', 'GrapeDuty').and_return(88)
          allow(@octo_obj).to receive(:team).and_raise(Octokit::NotFound.new)
        end

        it 'should return nil' do
          expect(github_repo.send(:gh_team, 'GrapeDuty', 'Wtf')).to eql nil
        end
      end

      context 'not even by the slug' do
        before do
          allow(github_repo).to receive(:team_id_by_slug).with('Wtf', 'GrapeDuty').and_return(nil)
          allow(@octo_obj).to receive(:team).and_raise(Octokit::NotFound.new)
        end

        it 'should return nil' do
          expect(github_repo.send(:gh_team, 'GrapeDuty', 'Wtf')).to eql nil
        end
      end
    end
  end

  describe '.repo_team_add' do
    before do
      match_data = { 'org' => github_org, 'repo' => 'lita-test', 'team' => 'HeckmanTest' }
      conf_obj = double('Lita::Configuration', default_org: 'GrapeDuty')
      @response = double('Lita::Response', match_data: match_data)
      team = { id: 42, name: 'HeckmanTest' }
      allow(github_repo).to receive(:config).and_return(conf_obj)
      allow(github_repo).to receive(:gh_team).with('GrapeDuty', 'HeckmanTest').and_return(team)
      allow(github_repo).to receive(:func_disabled?).and_return(false)
      allow(github_repo).to receive(:repo?).and_return(true)
      allow(github_repo).to receive(:repo_has_team?).and_return(false)
      allow(github_repo).to receive(:add_team_to_repo).and_return('attr')
    end

    context 'when valid inputs provided, and all things work out' do
      it 'should return the text from add_team_to_repo' do
        r = github_repo.send(:repo_team_add, @response)
        expect(r).to eql 'attr'
      end
    end

    context 'when function is disabled' do
      before { allow(github_repo).to receive(:func_disabled?).and_return(true) }

      it 'should return the method disabled error' do
        r = github_repo.send(:repo_team_add, @response)
        expect(r).to eql 'Sorry, this function has either been disabled or not enabled in the config'
      end
    end

    context 'when repo not found' do
      before { allow(github_repo).to receive(:repo?).and_return(false) }

      it 'should return the repo not found error' do
        r = github_repo.send(:repo_team_add, @response)
        expect(r).to eql 'That repo (GrapeDuty/lita-test) was not found'
      end
    end

    context 'when team not found' do
      before { allow(github_repo).to receive(:gh_team).and_return(nil) }

      it 'should return the team not found error' do
        r = github_repo.send(:repo_team_add, @response)
        expect(r).to eql 'Unable to match any teams based on: HeckmanTest'
      end
    end

    context 'when the team is already part of the repo' do
      before { allow(github_repo).to receive(:repo_has_team?).and_return(true) }

      it 'should mention that the team already exists on the repo' do
        r = github_repo.send(:repo_team_add, @response)
        expect(r).to eql "The 'HeckmanTest' team is already a member of GrapeDuty/lita-test"
      end
    end
  end

  describe '.repo_team_rm' do
    before do
      match_data = { 'org' => github_org, 'repo' => 'lita-test', 'team' => 'HeckmanTest' }
      conf_obj = double('Lita::Configuration', default_org: 'GrapeDuty')
      @response = double('Lita::Response', match_data: match_data)
      team = { id: 42, name: 'HeckmanTest' }
      allow(github_repo).to receive(:config).and_return(conf_obj)
      allow(github_repo).to receive(:func_disabled?).and_return(false)
      allow(github_repo).to receive(:gh_team).with('GrapeDuty', 'HeckmanTest').and_return(team)
      allow(github_repo).to receive(:repo?).and_return(true)
      allow(github_repo).to receive(:repo_has_team?).and_return(true)
      allow(github_repo).to receive(:remove_team_from_repo).and_return('rtfr')
    end

    context 'when valid inputs provided, and all things work out' do
      it 'should return the text from remove_team_to_repo' do
        r = github_repo.send(:repo_team_rm, @response)
        expect(r).to eql 'rtfr'
      end
    end

    context 'when function is disabled' do
      before { allow(github_repo).to receive(:func_disabled?).and_return(true) }

      it 'should return the method disabled error' do
        r = github_repo.send(:repo_team_rm, @response)
        expect(r).to eql 'Sorry, this function has either been disabled or not enabled in the config'
      end
    end

    context 'when repo not found' do
      before { allow(github_repo).to receive(:repo?).and_return(false) }

      it 'should return the repo not found error' do
        r = github_repo.send(:repo_team_rm, @response)
        expect(r).to eql 'That repo (GrapeDuty/lita-test) was not found'
      end
    end

    context 'when team not found' do
      before { allow(github_repo).to receive(:gh_team).and_return(nil) }

      it 'should return the team not found error' do
        r = github_repo.send(:repo_team_rm, @response)
        expect(r).to eql 'Unable to match any teams based on: HeckmanTest'
      end
    end

    context 'when the team is not part of the repo' do
      before { allow(github_repo).to receive(:repo_has_team?).and_return(false) }

      it 'should mention that the team already exists on the repo' do
        r = github_repo.send(:repo_team_rm, @response)
        expect(r).to eql "The 'HeckmanTest' team is not a member of GrapeDuty/lita-test"
      end
    end
  end

  describe '.repo_update_description' do
    before do
      match_data = { 'org' => github_org, 'repo' => 'lita-test', 'field' => 'description', 'content' => 'oh hello' }
      conf_obj = double('Lita::Configuration', default_org: 'GrapeDuty')
      @response = double('Lita::Response', match_data: match_data)
      @octo_obj = double('Octokit::Client', edit_repository: { description: 'oh hello' })
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:config).and_return(conf_obj)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).and_return(true)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:octo).and_return(@octo_obj)
    end

    context 'when valid inputs provided, and all things work out' do
      it 'should respond that the description was updated' do
        send_command('gh repo update description lita-test oh hello!')
        expect(replies.last).to eql "The description for GrapeDuty/lita-test has been updated to: 'oh hello'"
      end
    end

    context 'when function disabled' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(true)
      end

      it 'should return the method disabled error' do
        send_command('gh repo update description lita-test A new description!')
        expect(replies.last).to eql 'Sorry, this function has either been disabled or not enabled in the config'
      end
    end

    context 'when repo not found' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).and_return(false)
      end

      it 'should return the repo not found error' do
        send_command('gh repo update description lita-test A new description!')
        expect(replies.last).to eql 'That repo (GrapeDuty/lita-test) was not found'
      end
    end

    context 'when Octokit call explodes' do
      before { allow(@octo_obj).to receive(:edit_repository).and_raise(StandardError.new) }

      it 'should let us know things went a bit unexpected' do
        send_command('gh repo update description lita-test A new description!')
        expect(replies.last).to eql(
          'An uncaught exception was hit while trying to update the description of ' \
          'GrapeDuty/lita-test. Is GitHub having issues?'
        )
      end
    end
  end

  describe '.repo_update_homepage' do
    before do
      match_data = { 'org' => github_org, 'repo' => 'lita-test', 'field' => 'homepage', 'content' => 'https://test.it' }
      conf_obj = double('Lita::Configuration', default_org: 'GrapeDuty')
      @response = double('Lita::Response', match_data: match_data)
      @octo_obj = double('Octokit::Client', edit_repository: { homepage: 'https://test.it' })
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:config).and_return(conf_obj)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:octo).and_return(@octo_obj)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).and_return(true)
    end

    context 'when valid inputs provided, and all things work out' do
      it 'should respond that the homepage was updated' do
        send_command('gh repo update homepage lita-test https://test.it')
        expect(replies.last).to eql "The homepage for GrapeDuty/lita-test has been updated to: 'https://test.it'"
      end
    end

    context 'when function disabled' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(true)
      end

      it 'should return the method disabled error' do
        send_command('gh repo update homepage lita-test https://test.it')
        expect(replies.last).to eql 'Sorry, this function has either been disabled or not enabled in the config'
      end
    end

    context 'when repo not found' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).and_return(false)
      end

      it 'should return the repo not found error' do
        send_command('gh repo update homepage lita-test https://test.it')
        expect(replies.last).to eql 'That repo (GrapeDuty/lita-test) was not found'
      end
    end

    context 'when Octokit call explodes' do
      before { allow(@octo_obj).to receive(:edit_repository).and_raise(StandardError.new) }

      it 'should let us know things went a bit unexpected' do
        send_command('gh repo update homepage lita-test https://test.it')
        expect(replies.last).to eql(
          'An uncaught exception was hit while trying to update the homepage of ' \
          'GrapeDuty/lita-test. Is GitHub having issues?'
        )
      end
    end

    context 'when URL is invalid' do
      before do
        match_data = {
          'org' => github_org, 'repo' => 'lita-test',
          'field' => 'homepage', 'content' => 'https://test. it'
        }
        @response = double('Lita::Response', match_data: match_data)
      end

      it 'should return the invalid URL error' do
        send_command('gh repo update homepage lita-test https://test. it')
        expect(replies.last).to eql "The URL provided is not valid: 'https://test. it'"
      end
    end
  end

  ####
  # Handlers
  ####
  describe '.repo_info' do
    before do
      repo = {
        full_name: "#{github_org}/lita-test",
        description: 'unit testing',
        private: true,
        html_url: "https://stubbed.github.com/#{github_org}/lita-test",
        open_issues_count: 10
      }
      pr = [nil, nil, nil, nil, nil]
      @octo_obj = double('Octokit::Client', repository: repo, pull_requests: pr)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:octo).and_return(@octo_obj)
    end

    it 'should return some repo info' do
      send_command('gh repo info GrapeDuty/lita-test')
      r = "GrapeDuty/lita-test (private:true) :: https://stubbed.github.com/#{github_org}/lita-test\n" \
          "Desc: unit testing\n" \
          'Issues: 5 PRs: 5'
      expect(replies.last).to eql r
    end
  end

  describe '.repo_delete' do
    before do
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:delete_repo).and_return('hello there')
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).with("#{github_org}/lita-test").and_return(true)
    end

    it 'reply with the return from delete_repo()' do
      send_command("gh repo delete #{github_org}/lita-test")
      expect(replies.last).to eql 'hello there'
    end

    context 'when command disabled' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(true)
      end

      it 'should no-op and say such if the command is disabled' do
        send_command("gh repo delete #{github_org}/lita-test")
        expect(replies.last).to eql disabled_reply
      end
    end

    context 'when repo not found' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).with("#{github_org}/lita-test").and_return(false)
      end

      it 'should no-op informing you that the repo is not there' do
        send_command("gh repo delete #{github_org}/lita-test")
        expect(replies.last).to eql 'That repo (GrapeDuty/lita-test) was not found'
      end
    end
  end

  describe '.repo_create' do
    before do
      @opts = { private: true, team_id: 42, organization: github_org }
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).with("#{github_org}/lita-test").and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:extrapolate_create_opts).and_return(@opts)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:create_repo).and_return('hello from PAX prime!')
    end

    context 'when command disabled' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(true)
      end

      it 'should no-op and say such if the command is disabled' do
        send_command("gh repo create #{github_org}/lita-test")
        expect(replies.last).to eql disabled_reply
      end
    end

    context 'when repo already exists' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).with("#{github_org}/lita-test").and_return(true)
      end

      it 'should tell you it already exists' do
        send_command("gh repo create #{github_org}/lita-test")
        expect(replies.last).to eql 'Unable to create GrapeDuty/lita-test as it already exists'
      end
    end

    context 'when repo does not exist' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).with("#{github_org}/lita-test").and_return(false)
      end

      it 'should reply with the return of create_repo()' do
        expect_any_instance_of(Lita::Handlers::GithubRepo).to receive(:extrapolate_create_opts).and_return(@opts)
        send_command("gh repo create #{github_org}/lita-test")
        expect(replies.last).to eql 'hello from PAX prime!'
      end
    end
  end

  describe '.repo_rename' do
    before do
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(false)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:rename_repo).and_return('hello there')
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).with("#{github_org}/lita-test").and_return(true)
    end

    it 'reply with the return from rename_repo()' do
      send_command("gh repo rename #{github_org}/lita-test better-lita-test")
      expect(replies.last).to eql 'hello there'
    end

    context 'when command disabled' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:func_disabled?).and_return(true)
      end

      it 'should no-op and say such if the command is disabled' do
        send_command("gh repo rename #{github_org}/lita-test better-lita-test")
        expect(replies.last).to eql disabled_reply
      end
    end

    context 'when repo not found' do
      before do
        allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo?).with("#{github_org}/lita-test").and_return(false)
      end

      it 'should no-op informing you that the repo is not there' do
        send_command("gh repo rename #{github_org}/lita-test better-lita-test")
        expect(replies.last).to eql 'That repo (GrapeDuty/lita-test) was not found'
      end
    end
  end

  describe '.repo_teams_list' do
    before do
      @teams = [
        { name: 'Interns', slug: 'interns', id: 84, permission: 'pull' },
        { name: 'Everyone', slug: 'everyone', id: 42, permission: 'push' }
      ]
      @octo_obj = double('Octokit::Client', repository_teams: @teams)
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:octo).and_return(@octo_obj)
    end

    context 'when it finds a repo' do
      it 'should return the list of teams' do
        expect(@octo_obj).to receive(:repository_teams).with('GrapeDuty/lita-test').and_return(@teams)
        send_command("gh repo teams #{github_org}/lita-test")
        expect(replies.last).to eql 'Showing 2 team(s) for GrapeDuty/lita-test:
Name: Everyone, Slug: everyone, ID: 42, Perms: push
Name: Interns, Slug: interns, ID: 84, Perms: pull
'
      end
    end

    context 'when it finds a repo with no teams but the owners' do
      before { allow(@octo_obj).to receive(:repository_teams).and_return([]) }

      it 'should return the fact there are no teams' do
        send_command("gh repo teams #{github_org}/lita-test")
        expect(replies.last).to eql "Beyond the 'GrapeDuty' org owners, GrapeDuty/lita-test has no teams"
      end
    end

    context 'when the repo is not valid' do
      before { allow(@octo_obj).to receive(:repository_teams).and_raise(Octokit::NotFound.new) }

      it 'should say the repo was not found' do
        send_command("gh repo teams #{github_org}/lita-test")
        expect(replies.last).to eql 'That repo (GrapeDuty/lita-test) was not found'
      end
    end
  end

  describe '.repo_team_router' do
    before do
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo_team_add).with(an_instance_of(Lita::Response)).and_return('ohai')
    end

    it 'should call the method based on action and respond with its return' do
      expect_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo_team_add).with(an_instance_of(Lita::Response)).and_return('ohai')
      send_command("gh repo team add 42 #{github_org}/lita-test")
      expect(replies.last).to eql 'ohai'
    end
  end

  describe '.repo_update_router' do
    before do
      allow_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo_update_description).with(an_instance_of(Lita::Response)).and_return('ohai')
    end

    it 'should call the method based on the action and respond with its return' do
      expect_any_instance_of(Lita::Handlers::GithubRepo).to receive(:repo_update_description).with(an_instance_of(Lita::Response)).and_return('ohai')
      send_command("gh repo update description #{github_org}/lita-test Something funky here")
      expect(replies.last).to eql 'ohai'
    end
  end
end
