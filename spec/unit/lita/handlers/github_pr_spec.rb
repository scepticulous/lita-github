# -*- coding: UTF-8 -*-

require 'spec_helper'

describe Lita::Handlers::GithubPR, lita_handler: true do
  it { routes_command('gh shipit #42 GrapeDuty/lita-test').to(:pr_merge) }
  it { routes_command('gh pr merge #42 GrapeDuty/lita-test').to(:pr_merge) }
  it { routes_command('shipit #42 GrapeDuty/lita-test').to(:pr_merge) }

  let(:github_pr) { Lita::Handlers::GithubPR.new('robot') }
  let(:github_org) { 'GrapeDuty' }
  let(:github_repo) { 'lita-test' }
  let(:disabled_reply) { 'Sorry, this function has been disabled in the config' }

  describe '.pr_match' do
    it 'should return the content of the match data' do
      mock_md = { 'org' => github_org, 'repo' => github_repo, 'pr' => 42 }
      mock_resp = double('Lita::Response', match_data: mock_md)
      expect(github_pr.send(:pr_match, mock_resp)).to eql [github_org, github_repo, 42]
    end
  end

  describe '.pr_merge' do
    before do
      @cfg_obj = double('Lita::Configuration', pr_merge_enabled: true)
      @pr_obj =  { head: { ref: 'fix-some-bugs' }, title: 'fix bug' }
      @merge_status = { sha: 'abc456', merged: true, message: 'Pull Request successfully merged' }
      @octo_obj = double('Octokit::Client', pull_request: @pr_obj, merge_pull_request: @merge_status)
      allow(github_pr).to receive(:octo).and_return(@octo_obj)
      allow(github_pr).to receive(:func_disabled?).and_return(false)
      allow(github_pr).to receive(:config).and_return(@cfg_obj)
    end

    context 'when command disabled' do
      before do
        allow(github_pr).to receive(:func_disabled?).and_return(true)
      end

      it 'should no-op and say such if the command is disabled' do
        send_command("shipit #42 #{github_org}/#{github_repo}")
        expect(replies.last).to eql disabled_reply
      end
    end

    context 'when merging should succeed' do
      it 'should set the right commit message' do
        expect(@octo_obj).to receive(:merge_pull_request).with(
          'GrapeDuty/lita-test', '42', "Merge pull request #42 from GrapeDuty/fix-some-bugs\n\nfix bug"
        )
        send_command('shipit #42 GrapeDuty/lita-test')
      end

      it 'should confirm merging of PR' do
        send_command("shipit #42 #{github_org}/#{github_repo}")
        expect(replies.last)
          .to eql "Merged pull request #42 from GrapeDuty/fix-some-bugs\nfix bug"
      end
    end

    context 'when merging bombs' do
      before do
        @merge_status = { sha: 'abc456', merged: false, message: '*BOOM*' }
        @octo_obj = double('Octokit::Client', pull_request: @pr_obj, merge_pull_request: @merge_status)
        allow(github_pr).to receive(:octo).and_return(@octo_obj)
      end

      it 'should confirm the failure' do
        send_command("shipit #42 #{github_org}/#{github_repo}")
        expect(replies.last)
          .to eql(
            "Failed trying to merge PR #42 (fix bug) :: https://github.com/GrapeDuty/lita-test/pull/42\n"\
              'Message: *BOOM*'
          )
      end
    end

    context 'when the API request explodes' do
      before do
        @merge_status = { sha: 'abc456', merged: false, message: '*BOOM*' }
        @octo_obj = double('Octokit::Client', pull_request: @pr_obj)
        allow(@octo_obj).to receive(:merge_pull_request).and_raise(StandardError.new)
        allow(github_pr).to receive(:octo).and_return(@octo_obj)
      end

      it 'should confirm the failure' do
        send_command("shipit #42 #{github_org}/#{github_repo}")
        expect(replies.last)
          .to eql(
            'An unexpected exception was hit during the GitHub API operation. Please make sure all ' \
              'arguments are proper and try again, or try checking the GitHub status (gh status)'
          )
      end
    end
  end
end
