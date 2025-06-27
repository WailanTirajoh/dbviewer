require 'rails_helper'

RSpec.describe Dbviewer::PiiConfigurator do
  let(:configuration) { Dbviewer::Configuration.new }
  let(:configurator) { described_class.new(configuration) }

  describe '#mask' do
    it 'adds PII rules to configuration' do
      configurator.mask('users.email', with: :email)
      expect(configuration.pii_rules['users.email']).to eq(:email)
    end

    it 'accepts proc as masking rule' do
      custom_proc = ->(value) { "MASKED_#{value}" }
      configurator.mask('users.secret', with: custom_proc)
      expect(configuration.pii_rules['users.secret']).to eq(custom_proc)
    end
  end

  describe '#custom_mask' do
    it 'adds custom masks to configuration' do
      custom_proc = ->(value) { "CUSTOM_#{value}" }
      configurator.custom_mask(:my_mask, custom_proc)
      expect(configuration.custom_pii_masks[:my_mask]).to eq(custom_proc)
    end
  end

  describe '#enabled=' do
    it 'sets enable_pii_masking configuration' do
      configurator.enabled = false
      expect(configuration.enable_pii_masking).to be false
    end
  end
end
