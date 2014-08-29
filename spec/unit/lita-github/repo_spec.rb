# -*- coding: UTF-8 -*-

require 'spec_helper'

describe LitaGithub::Repo do
  include LitaGithub::Repo

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
end
