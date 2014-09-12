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

  describe '.sort_by_name' do
    let(:unsorted_list) do
      [
        { name: 'xy' }, { name: 'a' }, { name: 'Zx' }, { name: 'D' }, { name: 'z' }
      ]
    end
    let(:sorted_list) do
      [
        { name: 'a' }, { name: 'D' }, { name: 'xy' }, { name: 'z' }, { name: 'Zx' }
      ]
    end

    it 'should properly sort the list' do
      expect(sort_by_name(unsorted_list)).to eql sorted_list
    end
  end
end
