require 'rails_helper'

RSpec.describe "PII Masking Integration", type: :request do
  let(:original_rules) { Dbviewer.configuration.pii_rules.dup }
  let(:original_enabled) { Dbviewer.configuration.enable_pii_masking }

  before do
    Dbviewer.configuration.pii_rules.clear
    Dbviewer.configuration.enable_pii_masking = true

    # Configure some PII rules for testing
    Dbviewer.configuration.pii_rules['users.email'] = :email
    Dbviewer.configuration.pii_rules['users.phone'] = :phone
  end

  after do
    Dbviewer.configuration.pii_rules = original_rules
    Dbviewer.configuration.enable_pii_masking = original_enabled
  end

  describe "PII masking configuration" do
    it "can be configured using the configure_pii method" do
      # Clear existing rules first
      Dbviewer.configuration.pii_rules.clear
      expect(Dbviewer.configuration.pii_rules).to be_empty

      Dbviewer.configure_pii do |pii|
        pii.mask 'test.field', with: :email
        pii.custom_mask :test_mask, ->(value) { "TEST_#{value}" }
        pii.mask 'test.custom_field', with: :test_mask
      end

      expect(Dbviewer.configuration.pii_rules['test.field']).to eq(:email)
      expect(Dbviewer.configuration.pii_rules['test.custom_field']).to eq(:test_mask)
      expect(Dbviewer.configuration.custom_pii_masks[:test_mask]).to be_a(Proc)
    end
  end

  describe "FormattingHelper integration" do
    include Dbviewer::FormattingHelper

    it "applies PII masking when table and column are provided" do
      result = format_cell_value('test@example.com', 'users', 'email')
      expect(result).to eq('te***@example.com')
    end

    it "does not apply PII masking when table and column are not provided" do
      result = format_cell_value('test@example.com')
      expect(result).to eq('test@example.com')
    end

    it "handles nil values correctly" do
      result = format_cell_value(nil, 'users', 'email')
      expect(result).to eq('NULL')
    end
  end

  describe "End-to-end PII masking" do
    it "applies masking consistently across all components" do
      # Set up test data
      email = 'test@example.com'
      phone = '555-123-4567'

      # Test individual masking
      masked_email = Dbviewer::DataPrivacy::PiiMasker.mask_value(email, 'users', 'email')
      masked_phone = Dbviewer::DataPrivacy::PiiMasker.mask_value(phone, 'users', 'phone')

      expect(masked_email).to eq('te***@example.com')
      expect(masked_phone).to eq('55***67')
    end

    it "respects the global enable/disable setting" do
      email = 'test@example.com'

      # Test with masking enabled
      Dbviewer.configuration.enable_pii_masking = true
      masked_result = Dbviewer::DataPrivacy::PiiMasker.mask_value(email, 'users', 'email')
      expect(masked_result).to eq('te***@example.com')

      # Test with masking disabled
      Dbviewer.configuration.enable_pii_masking = false
      unmasked_result = Dbviewer::DataPrivacy::PiiMasker.mask_value(email, 'users', 'email')
      expect(unmasked_result).to eq('test@example.com')
    end

    it "integrates with FormattingHelper for consistent behavior" do
      helper = Object.new
      helper.extend(Dbviewer::FormattingHelper)

      email = 'john.doe@example.com'

      # Test direct masking
      direct_result = Dbviewer::DataPrivacy::PiiMasker.mask_value(email, 'users', 'email')

      # Test through FormattingHelper
      helper_result = helper.format_cell_value(email, 'users', 'email')

      expect(direct_result).to eq(helper_result)
      expect(helper_result).to eq('jo***@example.com')
    end
  end
end
