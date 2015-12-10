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

describe LitaGithub::General do
  include LitaGithub::General

  describe '.opts_parse' do
    it 'should find the valid options' do
      o = %q( private:true team:heckman Bacon:always bacon:sometimes string1:"something here" string2:'something else')
      co = opts_parse(o)
      expect(co).to be_an_instance_of Hash
      expect(co.key?(:Bacon)).to be_falsey
      expect(co.key?(:bacon)).to be_truthy
      expect(co[:bacon]).to eql 'always' # of course it's always
      expect(co[:bacon]).to_not eql 'sometimes'
      expect(co[:private]).to eql 'true'
      expect(co[:team]).to eql 'heckman'
      expect(co[:string1]).to eql 'something here'
      expect(co[:string2]).to eql 'something else'
    end

    it 'should should parse words with dashes' do
      o = ' team:dash-team '
      co = opts_parse(o)
      expect(co).to be_an_instance_of Hash
      expect(co[:team]).to eql 'dash-team'
    end
  end

  describe '.to_i_if_numeric' do
    context 'when value is a number' do
      subject { to_i_if_numeric('42') }
      it { should eql 42 }
    end

    context 'when value is not a number' do
      let(:val) { 'hello' }
      subject { to_i_if_numeric(val) }
      it { should eql val }
    end
  end

  describe '.symbolize_opt_key' do
    it 'should return an Array with the downcased/symblized key' do
      kv = %w(Hello! ohai)
      a = symbolize_opt_key(*kv)
      expect(a).to be_an_instance_of Array
      expect(a[0]).to eql kv[0].downcase.to_sym
      expect(a[1]).to eql kv[1]
    end
  end
end
