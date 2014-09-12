# -*- coding: UTF-8 -*-

require 'spec_helper'

describe LitaGithub::Repo do
  include LitaGithub::Repo

  describe '::PR_LIST_MAX_COUNT' do
    subject { LitaGithub::Repo::PR_LIST_MAX_COUNT }

    it { should be_an_instance_of Fixnum }
    it { should eql 20 }
  end

  describe '.rpo' do
    it 'should return the provided arguments in a Repo-like string' do
      org = 'GrapeDuty'
      repo = 'lita-test'
      expect(rpo(org, repo)).to eql "#{org}/#{repo}"
    end
  end

  describe '.repo?' do
    before do
      @octo = double('Octokit::Client', repository?: true)
      allow(self).to receive(:octo).and_return(@octo)
    end

    context 'when repo exists' do
      subject { repo?('GrapeDuty/lita-test') }
      it { should be_truthy }
    end

    context 'when repo does not exist' do
      before do
        @octo = double('Octokit::Client', repository?: false)
        allow(self).to receive(:octo).and_return(@octo)
      end

      subject { repo?('GrapeDuty/lita-test') }
      it { should be_falsey }
    end
  end

  describe '.repo_match' do
    before { allow(self).to receive(:organization).and_return('GrapeDuty') }

    let(:match_data) { { 'org' => 'GrapeDuty', 'repo' => 'lita-test' } }

    it 'should return the Org/Repo match' do
      expect(repo_match(match_data)).to eql ['GrapeDuty', 'lita-test']
    end
  end

  describe '.repo_has_team?' do
    before do
      @teams = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }]
      @octo_obj = double('Octokit::Client', repository_teams: @teams)
      allow(self).to receive(:octo).and_return(@octo_obj)
    end

    context 'when repo has the team' do
      it 'should return be truthy' do
        expect(@octo_obj).to receive(:repository_teams).with('GrapeDuty/lita-test').and_return(@teams)
        expect(repo_has_team?('GrapeDuty/lita-test', 4)).to be_truthy
      end
    end

    context 'when the repo does not have the team' do
      it 'should be falsey' do
        expect(repo_has_team?('GrapeDuty/lita-test', 42)).to be_falsey
      end
    end
  end
end
