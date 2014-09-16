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

describe Lita::Handlers::Github, lita_handler: true do
  let(:github) { Lita::Handlers::Github.new('robot') }

  # status routing
  it { routes_command('gh status').to(:status) }
  it { routes_command('github status').to(:status) }

  # version routing
  it { routes_command('gh version').to(:version) }

  # token routing
  it { routes_command('gh token').to(:token_generate) }

  # whois routing
  it { routes_command('gh whois theckman').to(:whois) }
  it { routes_command('gh user theckman').to(:whois) }

  describe '#default_config' do
    it 'should set default team to nil' do
      expect(Lita.config.handlers.github.default_team_slug).to be_nil
    end

    it 'should set repos to private by default' do
      expect(Lita.config.handlers.github.repo_private_default).to be_truthy
    end

    it 'should enable Lita::Handlers::GithubRepo.repo_create by default' do
      expect(Lita.config.handlers.github.repo_create_enabled).to be_truthy
    end

    it 'should disable Lita::Handlers::GithubRepo.repo_delete by default' do
      expect(Lita.config.handlers.github.repo_delete_enabled).to be_falsey
    end

    it 'should disable Lita::Handlers::GithubRepo.repo_team_add by default' do
      expect(Lita.config.handlers.github.repo_team_add_enabled).to be_falsey
    end

    it 'should disable Lita::Handlers::GithubRepo.repo_team_rm by default' do
      expect(Lita.config.handlers.github.repo_team_rm_enabled).to be_falsey
    end

    it 'should enale Lita::Handlers::GithubRepo.repo_update_description by default' do
      expect(Lita.config.handlers.github.repo_update_description_enabled).to be_truthy
    end

    it 'should enale Lita::Handlers::GithubRepo.repo_update_homepage by default' do
      expect(Lita.config.handlers.github.repo_update_homepage_enabled).to be_truthy
    end

    it 'should enable Lita::Handlers::GithubPR.pr_merge by default' do
      expect(Lita.config.handlers.github.pr_merge_enabled).to be_truthy
    end

    it 'should disable Lita::Handlers::GithubOrg.org_team_add by default' do
      expect(Lita.config.handlers.github.org_team_add_enabled).to be_falsey
    end

    it 'should disable Lita::Handlers::GithubOrg.org_team_rm by default' do
      expect(Lita.config.handlers.github.org_team_rm_enabled).to be_falsey
    end

    it 'should allow only teams with "pull" permissions to be created by default' do
      expect(Lita.config.handlers.github.org_team_add_allowed_perms).to eql %w(pull)
    end
  end

  ####
  # Helper Methods
  ####
  describe '.key_valid?' do
    context 'when value is nil' do
      it 'should be false' do
        expect(github.send(:key_valid?, nil)).to be_falsey
      end
    end

    context 'when value is empty String ("")' do
      it 'should be false' do
        expect(github.send(:key_valid?, '')).to be_falsey
      end
    end

    context 'when value is a String' do
      it 'should be true' do
        expect(github.send(:key_valid?, 'something')).to be_truthy
      end
    end
  end

  describe '.whois_reply' do
    before do
      @user_obj = {
        name: 'Tim Heckman',
        login: 'theckman',
        location: 'San Francisco, CA',
        company: 'PagerDuty, Inc.',
        id: 787_332,
        email: 'tim@pagerduty.com',
        html_url: 'https://github.com/theckman',
        site_admin: false,
        public_repos: 42,
        public_gists: 1,
        following: 20,
        followers: 10,
        created_at: Time.parse('2011-05-14 04:16:33 UTC')
      }
      @orgs = %w(PagerDuty GrapeDuty)
    end

    context 'when all fields are there' do
      it 'should reply with the proper response' do
        r = github.send(:whois_reply, @user_obj, @orgs)
        expect(r).to eql 'theckman (Tim Heckman) :: https://github.com/theckman
Located: San Francisco, CA
Company: PagerDuty, Inc.
Orgs: PagerDuty, GrapeDuty
ID: 787332, Email: tim@pagerduty.com
GitHub Admin: false, Repos: 42, Gists: 1
Following: 20, Followers: 10, Created: 2011-05-14 04:16:33 UTC'
      end
    end

    context 'when name is unset' do
      before { @user_obj.delete(:name) }

      it 'should reply with the proper response' do
        r = github.send(:whois_reply, @user_obj, @orgs)
        expect(r).to eql 'theckman :: https://github.com/theckman
Located: San Francisco, CA
Company: PagerDuty, Inc.
Orgs: PagerDuty, GrapeDuty
ID: 787332, Email: tim@pagerduty.com
GitHub Admin: false, Repos: 42, Gists: 1
Following: 20, Followers: 10, Created: 2011-05-14 04:16:33 UTC'
      end
    end

    context 'when location is unset' do
      before { @user_obj.delete(:location) }

      it 'should reply with the proper response' do
        r = github.send(:whois_reply, @user_obj, @orgs)
        expect(r).to eql 'theckman (Tim Heckman) :: https://github.com/theckman
Company: PagerDuty, Inc.
Orgs: PagerDuty, GrapeDuty
ID: 787332, Email: tim@pagerduty.com
GitHub Admin: false, Repos: 42, Gists: 1
Following: 20, Followers: 10, Created: 2011-05-14 04:16:33 UTC'
      end
    end

    context 'when company is unset' do
      before { @user_obj.delete(:company) }

      it 'should reply with the proper response' do
        r = github.send(:whois_reply, @user_obj, @orgs)
        expect(r).to eql 'theckman (Tim Heckman) :: https://github.com/theckman
Located: San Francisco, CA
Orgs: PagerDuty, GrapeDuty
ID: 787332, Email: tim@pagerduty.com
GitHub Admin: false, Repos: 42, Gists: 1
Following: 20, Followers: 10, Created: 2011-05-14 04:16:33 UTC'
      end
    end

    context 'when orgs is empty' do
      before { @orgs.clear }

      it 'should reply with the proper response' do
        r = github.send(:whois_reply, @user_obj, @orgs)
        expect(r).to eql 'theckman (Tim Heckman) :: https://github.com/theckman
Located: San Francisco, CA
Company: PagerDuty, Inc.
ID: 787332, Email: tim@pagerduty.com
GitHub Admin: false, Repos: 42, Gists: 1
Following: 20, Followers: 10, Created: 2011-05-14 04:16:33 UTC'
      end
    end

    context 'when email is empty string' do
      before { @user_obj[:email] = '' }

      it 'should reply with the proper response' do
        r = github.send(:whois_reply, @user_obj, @orgs)
        expect(r).to eql 'theckman (Tim Heckman) :: https://github.com/theckman
Located: San Francisco, CA
Company: PagerDuty, Inc.
Orgs: PagerDuty, GrapeDuty
ID: 787332
GitHub Admin: false, Repos: 42, Gists: 1
Following: 20, Followers: 10, Created: 2011-05-14 04:16:33 UTC'
      end
    end
  end

  ####
  # Handlers
  ####
  describe '.status' do
    context 'when GitHub status is good' do
      before do
        @octo = double(
          'Octokit::Client',
          github_status_last_message: {
            status: 'good', body: 'Everything is operating normally.',
            created_on: '1970-01-01 00:00:00 UTC'
          }
        )
        allow_any_instance_of(Lita::Handlers::Github).to receive(:octo).and_return(@octo)
      end

      it 'should return the current GitHub status' do
        send_command('gh status')
        expect(replies.last).to eql('GitHub is reporting that all systems are green!')
      end
    end

    context 'when GitHub status is minor' do
      before do
        @octo = double(
          'Octokit::Client',
          github_status_last_message: {
            status: 'minor', body: 'Minor issue',
            created_on: '1970-01-01 00:00:21 UTC'
          }
        )
        allow_any_instance_of(Lita::Handlers::Github).to receive(:octo).and_return(@octo)
      end

      it 'should return the current GitHub status' do
        send_command('gh status')
        expect(replies.last).to eql(
          "GitHub is reporting minor issues (status:yellow)! Last message:\n" \
            '1970-01-01 00:00:21 UTC :: Minor issue'
        )
      end
    end

    context 'when GitHub status is major' do
      before do
        @octo = double(
          'Octokit::Client',
          github_status_last_message: {
            status: 'major', body: 'Major issue',
            created_on: '1970-01-01 00:00:42 UTC'
          }
        )
        allow_any_instance_of(Lita::Handlers::Github).to receive(:octo).and_return(@octo)
      end

      it 'should return the current GitHub status' do
        send_command('gh status')
        expect(replies.last).to eql(
          "GitHub is reporting major issues (status:red)! Last message:\n" \
            '1970-01-01 00:00:42 UTC :: Major issue'
        )
      end
    end
  end

  describe '.version' do
    it 'should send back the Lita version' do
      send_command('gh version')
      expect(replies.last).to eql "lita-github v#{LitaGithub::VERSION}"
    end
  end

  describe '.token_generate' do
    before do
      @secret = 'GZSDEMLDMY3TQYLG'
      conf_obj = double('Lita::Configuration', totp_secret: @secret)
      allow(github).to receive(:config).and_return(conf_obj)
    end

    context 'when token is set' do
      it 'should return the correct totp token' do
        t = ROTP::TOTP.new(@secret)
        send_command('gh token')
        expect(replies.last).to eql t.now
      end
    end

    context 'when token is not set' do
      before do
        conf_obj = double('Lita::Configuration', totp_secret: nil)
        allow(github).to receive(:config).and_return(conf_obj)
      end

      it 'should return the error message' do
        send_command('gh token')
        expect(replies.last)
          .to eql "'totp_secret' has not been provided in the config, unable to generate TOTP"
      end
    end
  end

  describe '.whois' do
    before do
      @user_obj = {
        name: 'Tim Heckman',
        login: 'theckman',
        location: 'San Francisco, CA',
        company: 'PagerDuty, Inc.',
        id: 787_332,
        email: 'tim@pagerduty.com',
        html_url: 'https://github.com/theckman',
        site_admin: false,
        public_repos: 42,
        public_gists: 1,
        following: 20,
        followers: 10,
        created_at: Time.parse('2011-05-14 04:16:33 UTC')
      }
      @orgs = [{ login: 'PagerDuty' }, { login: 'GrapeDuty' }]
      @octo_obj = double('Octokit::Client', user: @user_obj, organizations: @orgs)
      allow(github).to receive(:octo).and_return(@octo_obj)
      allow(github).to receive(:whois_reply).and_return('StubbedResponse')
    end

    context 'when all goes well' do
      it 'should return the response from whois_reply' do
        expect(@octo_obj).to receive(:user).with('theckman').and_return(@user_obj)
        expect(@octo_obj).to receive(:organizations).with('theckman').and_return(@orgs)
        expect(github).to receive(:whois_reply).with(@user_obj, %w(PagerDuty GrapeDuty)).and_return('StubbedResponse')
        send_command('gh whois theckman')
        expect(replies.last).to eql 'StubbedResponse'
      end
    end

    context 'when user can not be found' do
      before { allow(@octo_obj).to receive(:user).with('theckman').and_raise(Octokit::NotFound.new) }

      it 'should return the response from whois_reply' do
        send_command('gh whois theckman')
        expect(replies.last).to eql 'Sorry, unable to locate the GitHub user theckman'
      end
    end
  end
end
