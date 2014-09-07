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

    let(:resp_obj) do
      md_mock = { 'org' => 'GrapeDuty', 'repo' => 'lita-test' }
      double('Lita::Response', match_data: md_mock)
    end

    it 'should return the Org/Repo match' do
      expect(repo_match(resp_obj)).to eql ['GrapeDuty', 'lita-test']
    end
  end
end
