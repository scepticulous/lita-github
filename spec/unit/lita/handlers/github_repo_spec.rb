# -*- coding: UTF-8 -*-
#
# Copyright 2014 GrapeDuty, Inc.
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
  it { routes_command('gh repo create GrapeDuty/lita-test').to(:repo_create) }
  it { routes_command('gh repo new GrapeDuty/lita-test').to(:repo_create) }
  it { routes_command('gh repo new lita-test').to(:repo_create) }
  it { routes_command('gh repo new GrapeDuty/lita-test private:true team:heckman').to(:repo_create) }
  it { routes_command('gh repo new GrapeDuty/lita-test private:true randomunparseabletext ').to(:repo_create) }

  # repo_delete command routing
  it { routes_command('gh repo delete GrapeDuty/lita-test').to(:repo_delete) }
  it { routes_command('gh repo delete lita-test').to(:repo_delete) }

  # repo_info command routing
  it { routes_command('gh repo info GrapeDuty/lita-test').to(:repo_info) }
  it { routes_command('gh repo info lita-test').to(:repo_info) }

  let(:github_repo) { Lita::Handlers::GithubRepo.new('robot') }
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

  describe '.team_by_slug' do
    before do
      @teams = [
        { id: 1, slug: 'hi' },
        { id: 42, slug: 'heckman' },
        { id: 84, slug: 'orwell' }
      ]
      @octo_obj = double('Octokit::Client', organization_teams: @teams)
      allow(github_repo).to receive(:octo).and_return(@octo_obj)
    end

    it 'should return the team id of the team matching the slug' do
      expect(@octo_obj).to receive(:organization_teams).with(github_org).and_return(@teams)
      expect(github_repo.send(:team_by_slug, 'heckman', github_org)).to eql 42
      expect(github_repo.send(:team_by_slug, 'orwell', github_org)).to eql 84
      expect(github_repo.send(:team_by_slug, 'unknown', github_org)).to be_nil
    end

    it 'should return nil if unknown' do
      expect(github_repo.send(:team_by_slug, 'unknown', 'x')).to be_nil
    end
  end

  describe '.extrapolate_create_opts' do
    before do
      @eco_opts = {}
      @c_obj = double('Lita::Configuration', default_team_slug: 'h3ckman')
      allow(github_repo).to receive(:config).and_return(@c_obj)
      allow(github_repo).to receive(:team_by_slug).and_return(42)
    end

    it 'should set the :organization key and :team_id key' do
      h = { organization: github_org, team_id: 42 }
      expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
    end

    context 'when options contains :team and no :team_id' do
      context 'when given a valid slug' do
        before { @eco_opts = { team: 'heckman' } }

        it 'should set the :team_id key' do
          h = { organization: github_org, team_id: 84 }.merge!(@eco_opts)
          expect(github_repo).to receive(:team_by_slug).with('heckman', github_org).and_return(84)
          expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
        end
      end

      context 'when given an invalid slug' do
        it 'should set the team to the default' do
          h = { organization: github_org, team_id: 42 }.merge!(@eco_opts)
          expect(github_repo).to receive(:team_by_slug).with('h3ckman', github_org).and_return(42)
          expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
        end
      end
    end

    context 'when there is a :team_id key' do
      before { @eco_opts = { team_id: 44 } }

      it 'should just leave it alone...' do
        h = { organization: github_org }.merge!(@eco_opts)
        expect(github_repo).not_to receive(:team_by_slug)
        expect(github_repo.send(:extrapolate_create_opts, @eco_opts, github_org)).to eql h
      end
    end
  end

  describe '.repo_match' do
    let(:resp_obj) do
      md_mock = { 'org' => github_org, 'repo' => 'lita-test' }
      double('Lita::Response', match_data: md_mock)
    end

    it 'should return the Org/Repo match' do
      expect(github_repo.send(:repo_match, resp_obj)).to eql [github_org, 'lita-test']
    end
  end

  describe '.command_opts' do
    it 'should find the valid options' do
      o = ' private:true team:heckman bacon:always bacon:sometimes'
      co = github_repo.send(:command_opts, o)
      expect(co).to be_an_instance_of Hash
      expect(co[:private]).to eql 'true'
      expect(co[:team]).to eql 'heckman'
      expect(co[:bacon]).to eql 'always' # of course it's always
    end
  end

  describe '.create_repo' do
    before do
      allow(github_repo).to receive(:octo).and_return(double('Octokit::Client', create_repository: nil))
    end

    context 'when repo created' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(true)
      end

      it 'should confirm succesfful creation' do
        opts = { private: true, team_id: 42, organization: github_org }
        expect(github_repo.send(:create_repo, github_org, 'lita-test', opts))
          .to eql 'Created GrapeDuty/lita-test: https://github.com/GrapeDuty/lita-test'
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
      allow(github_repo).to receive(:octo).and_return(@octo_obj)
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
      allow(github_repo).to receive(:func_disabled?).and_return(false)
      allow(github_repo).to receive(:delete_repo).and_return('hello there')
      allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(true)
    end

    it 'reply with the return from delete_repo()' do
      send_command("gh repo delete #{github_org}/lita-test")
      expect(replies.last).to eql 'hello there'
    end

    context 'when command disabled' do
      before do
        allow(github_repo).to receive(:func_disabled?).and_return(true)
      end

      it 'should no-op and say such if the command is disabled' do
        send_command("gh repo delete #{github_org}/lita-test")
        expect(replies.last).to eql disabled_reply
      end
    end

    context 'when repo not found' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(false)
      end

      it 'should no-op informing you that the repo is not there' do
        send_command("gh repo delete #{github_org}/lita-test")
        expect(replies.last).to eql 'That repo (GrapeDuty/lita-test) does not exist'
      end
    end
  end

  describe '.repo_create' do
    before do
      @opts = { private: true, team_id: 42, organization: github_org }
      allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(false)
      allow(github_repo).to receive(:extrapolate_create_opts).and_return(@opts)
      allow(github_repo).to receive(:create_repo).and_return('hello from PAX prime!')
    end

    context 'when repo already exists' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(true)
      end

      it 'should tell you it already exists' do
        send_command("gh repo create #{github_org}/lita-test")
        expect(replies.last).to eql 'Unable to create GrapeDuty/lita-test as it already exists'
      end
    end

    context 'when repo does not exist' do
      before do
        allow(github_repo).to receive(:repo?).with("#{github_org}/lita-test").and_return(false)
      end

      it 'should reply with the return of create_repo()' do
        expect(github_repo).to receive(:extrapolate_create_opts).and_return(@opts)
        send_command("gh repo create #{github_org}/lita-test")
        expect(replies.last).to eql 'hello from PAX prime!'
      end
    end
  end
end
