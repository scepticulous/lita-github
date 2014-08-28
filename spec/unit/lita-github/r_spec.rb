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

describe LitaGithub::R do
  describe '::A_REG' do
    subject { Regexp.new(LitaGithub::R::A_REG) }

    context 'it should match' do
      it 'gh ' do
        expect(subject.match('gh ')).to_not be_nil
      end

      it 'github ' do
        expect(subject.match('github ')).to_not be_nil
      end
    end

    context 'it should not match' do
      it 'gh' do
        expect(subject.match('gh')).to be_nil
      end

      it 'github' do
        expect(subject.match('github')).to be_nil
      end
    end
  end

  describe '::OPT_REGEX' do
    subject { LitaGithub::R::OPT_REGEX }

    context 'it should match' do
      it 'test:pass' do
        expect(subject.match(' test:pass')).to_not be_nil
      end

      it 'test7_pass:pAss_test' do
        expect(subject.match(' test7_pass:pAss_test')).to_not be_nil
      end
    end

    context 'it should not match' do
      it 'test-stuff:fail' do
        expect(subject.match(' test-stuff:fail')).to be_nil
      end

      it 'test: fail' do
        expect(subject.match(' test: fail')).to be_nil
      end

      it 'test:fail' do
        expect(subject.match('test:fail')).to be_nil
      end
    end
  end

  describe '::REPO_REGEX' do
    subject { Regexp.new(LitaGithub::R::REPO_REGEX) }

    context 'it should match' do
      it 'PagerDuty/lita-github' do
        expect(subject.match('PagerDuty/lita-github')).to_not be_nil
      end

      it 'lita-github' do
        expect(subject.match('lita-github')).to_not be_nil
      end

      it 'PagerDuty /lita-github' do
        expect(subject.match('PagerDuty /lita-github')).to_not be_nil
      end

      it 'PagerDuty/ lita-github' do
        expect(subject.match('PagerDuty/ lita-github')).to_not be_nil
      end
    end
  end
end
