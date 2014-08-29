# -*- coding: UTF-8 -*-

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
