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
      o = ' private:true team:heckman bacon:always bacon:sometimes'
      co = opts_parse(o)
      expect(co).to be_an_instance_of Hash
      expect(co[:private]).to eql 'true'
      expect(co[:team]).to eql 'heckman'
      expect(co[:bacon]).to eql 'always' # of course it's always
    end
  end

  describe '.e_opts_parse' do
    it 'should find the valid options' do
      o = %q( private:true team:heckman bacon:always bacon:sometimes string1:"something here" string2:'something else')
      co = e_opts_parse(o)
      expect(co).to be_an_instance_of Hash
      expect(co[:private]).to eql 'true'
      expect(co[:team]).to eql 'heckman'
      expect(co[:bacon]).to eql 'always' # of course it's always
      expect(co[:string1]).to eql 'something here'
      expect(co[:string2]).to eql 'something else'
    end
  end
end
