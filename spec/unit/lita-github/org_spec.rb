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

  describe '.team_id_by_slug' do
    before do
      @teams = [
        { id: 1, slug: 'hi' },
        { id: 42, slug: 'heckman' },
        { id: 84, slug: 'orwell' }
      ]
      @octo_obj = double('Octokit::Client', organization_teams: @teams)
      allow(self).to receive(:octo).and_return(@octo_obj)
    end

    it 'should return the team id of the team matching the slug' do
      expect(@octo_obj).to receive(:organization_teams).with('GrapeDuty').and_return(@teams)
      expect(team_id_by_slug('heckman', 'GrapeDuty')).to eql 42
      expect(team_id_by_slug('orwell', 'GrapeDuty')).to eql 84
      expect(team_id_by_slug('unknown', 'GrapeDuty')).to be_nil
    end

    it 'should return nil if unknown' do
      expect(team_id_by_slug('unknown', 'x')).to be_nil
    end
  end

  describe '.team_id' do
    before { allow(self).to receive(:team_id_by_slug).and_return(84) }

    context 'when value is an "Integer"' do
      it 'should return the value passed in' do
        v = 42
        expect(team_id(v, 'GrapeDuty')).to eql v
      end
    end

    context 'when the value is not an Integer' do
      it 'should return the id from team_id_by_slug()' do
        expect(self).to receive(:team_id_by_slug).with('TestIt', 'GrapeDuty').and_return(84)
        expect(team_id('TestIt', 'GrapeDuty')).to eql 84
      end
    end
  end

  describe '.team?' do
    before do
      @octo_obj = double('Octokit::Client', team: {})
      allow(self).to receive(:octo).and_return(@octo_obj)
    end

    it 'should try to load the team' do
      expect(@octo_obj).to receive(:team).with(42).and_return(nil)
      team?(42)
    end

    context 'when team exists' do
      it 'should return true' do
        expect(team?(42)).to be_truthy
      end
    end

    context 'when team does not exist' do
      before { allow(@octo_obj).to receive(:team).and_raise(Octokit::NotFound.new) }

      it 'should return false' do
        expect(team?(42)).to be_falsey
      end
    end
  end
end
