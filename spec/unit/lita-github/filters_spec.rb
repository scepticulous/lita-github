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

describe LitaGithub::Filters do
  include LitaGithub::Filters

  describe '.func_disabled?' do
    before do
      @cfg = double('Lita::Configuration', test_enabled: true)
      allow(self).to receive(:config).and_return(@cfg)
    end

    context 'when enabled' do
      it 'should return false' do
        expect(func_disabled?(:test)).to be_falsey
      end
    end

    context 'when disabled' do
      before do
        @cfg = double('Lita::Configuration', test_enabled: false)
        allow(self).to receive(:config).and_return(@cfg)
      end

      it 'should return true' do
        expect(func_disabled?(:test)).to be_truthy
      end
    end
  end
end
