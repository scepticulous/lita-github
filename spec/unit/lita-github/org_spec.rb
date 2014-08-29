# -*- coding: UTF-8 -*-

require 'spec_helper'

describe LitaGithub::Org do
  include LitaGithub::Org

  describe '.organization' do
    before do
      @cfg = double('Lita::Config', default_org: 'GrapeDuty')
      allow(self).to receive(:config).and_return(@cfg)
    end

    context 'when name provided is nil' do
      it 'should use the default' do
        expect(organization(nil)).to eql 'GrapeDuty'
      end
    end

    context 'when name provided is empty string ("")' do
      it 'should use the default' do
        expect(organization('')).to eql 'GrapeDuty'
      end
    end

    context 'when name provided is not nil or not empty string' do
      it 'should use the name provided' do
        expect(organization('testing')).to eql 'testing'
      end
    end
  end
end
