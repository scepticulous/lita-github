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

class DoubleFixer
  class << self
    attr_accessor :auto_paginate
  end
end

# Dummy class for testing some mixin
class DummyClass
  include LitaGithub::Octo
  extend LitaGithub::Octo
end

describe LitaGithub::Octo do
  before do
    allow(Octokit::Client).to receive(:new).with(access_token: 'abc123').and_return(DoubleFixer)
    @conf_obj = double('Lita::Config', access_token: 'abc123')
    allow(self).to receive(:config).and_return(@conf_obj)
    allow_any_instance_of(DummyClass).to receive(:config).and_return(@conf_obj)
    @dummy = DummyClass.new
    @dummy.setup_octo(nil)
  end
  after(:all) { allow(Octokit::Client).to receive(:new).and_call_original }

  include LitaGithub::Octo

  describe '.access_token' do
    it 'should return the access token' do
      expect(access_token).to eql 'abc123'
    end
  end

  describe '.setup_octo' do
    it 'should set up the Octokit client instance' do
      x = DummyClass.class_variable_get(:@@octo)
      expect(x).to eql DoubleFixer
    end

    it 'should turn on auto pagination' do
      expect(DoubleFixer).to receive(:auto_paginate=).with(true)
      DummyClass.setup_octo(nil)
    end
  end

  describe '.octo' do
    it 'should return the @@octo instance variable' do
      expect(@dummy.octo).to eql DoubleFixer
    end
  end
end
