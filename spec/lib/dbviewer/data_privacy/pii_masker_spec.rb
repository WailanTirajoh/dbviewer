require 'rails_helper'

RSpec.describe Dbviewer::DataPrivacy::PiiMasker do
  let(:original_rules) { Dbviewer.configuration.pii_rules.dup }
  let(:original_enabled) { Dbviewer.configuration.enable_pii_masking }
  let(:original_custom_masks) { Dbviewer.configuration.custom_pii_masks.dup }

  before do
    # Reset configuration before each test
    Dbviewer.configuration.pii_rules.clear
    Dbviewer.configuration.enable_pii_masking = true
    Dbviewer.configuration.custom_pii_masks.clear
  end

  after do
    # Restore original configuration after each test
    Dbviewer.configuration.pii_rules = original_rules
    Dbviewer.configuration.enable_pii_masking = original_enabled
    Dbviewer.configuration.custom_pii_masks = original_custom_masks
  end

  describe '.mask_value' do
    context 'when PII masking is disabled' do
      before { Dbviewer.configuration.enable_pii_masking = false }

      it 'returns original value without masking' do
        Dbviewer.configuration.pii_rules['users.email'] = :email
        result = described_class.mask_value('test@example.com', 'users', 'email')
        expect(result).to eq('test@example.com')
      end
    end

    context 'when no PII rules are configured' do
      it 'returns original value without masking' do
        result = described_class.mask_value('test@example.com', 'users', 'email')
        expect(result).to eq('test@example.com')
      end
    end

    context 'when column is not in PII rules' do
      before { Dbviewer.configuration.pii_rules['users.email'] = :email }

      it 'returns original value without masking' do
        result = described_class.mask_value('John Doe', 'users', 'name')
        expect(result).to eq('John Doe')
      end
    end

    context 'with built-in masking types' do
      describe ':email masking' do
        before { Dbviewer.configuration.pii_rules['users.email'] = :email }

        it 'masks email addresses correctly' do
          result = described_class.mask_value('john.doe@example.com', 'users', 'email')
          expect(result).to eq('jo***@example.com')
        end

        it 'handles short emails' do
          result = described_class.mask_value('a@b.com', 'users', 'email')
          expect(result).to eq('*@b.com')
        end

        it 'handles nil values' do
          result = described_class.mask_value(nil, 'users', 'email')
          expect(result).to be_nil
        end

        it 'handles non-email values' do
          result = described_class.mask_value('not-an-email', 'users', 'email')
          expect(result).to eq('not-an-email')
        end
      end

      describe ':phone masking' do
        before { Dbviewer.configuration.pii_rules['users.phone'] = :phone }

        it 'masks phone numbers correctly' do
          result = described_class.mask_value('+1234567890', 'users', 'phone')
          expect(result).to eq('12***90')
        end

        it 'handles formatted phone numbers' do
          result = described_class.mask_value('555-123-4567', 'users', 'phone')
          expect(result).to eq('55***67')
        end

        it 'handles short numbers' do
          result = described_class.mask_value('1234', 'users', 'phone')
          expect(result).to eq('1**4')
        end
      end

      describe ':ssn masking' do
        before { Dbviewer.configuration.pii_rules['users.ssn'] = :ssn }

        it 'masks SSN correctly' do
          result = described_class.mask_value('123456789', 'users', 'ssn')
          expect(result).to eq('***-**-6789')
        end

        it 'handles formatted SSN' do
          result = described_class.mask_value('123-45-6789', 'users', 'ssn')
          expect(result).to eq('***-**-6789')
        end

        it 'handles invalid SSN length' do
          result = described_class.mask_value('12345', 'users', 'ssn')
          expect(result).to eq('12345')
        end
      end

      describe ':credit_card masking' do
        before { Dbviewer.configuration.pii_rules['payments.card'] = :credit_card }

        it 'masks credit card numbers correctly' do
          result = described_class.mask_value('1234567890123456', 'payments', 'card')
          expect(result).to eq('****-****-****-3456')
        end

        it 'handles formatted card numbers' do
          result = described_class.mask_value('1234-5678-9012-3456', 'payments', 'card')
          expect(result).to eq('****-****-****-3456')
        end
      end

      describe ':full_redact masking' do
        before { Dbviewer.configuration.pii_rules['users.secret'] = :full_redact }

        it 'fully redacts values' do
          result = described_class.mask_value('sensitive_data', 'users', 'secret')
          expect(result).to eq('***REDACTED***')
        end

        it 'handles nil values' do
          result = described_class.mask_value(nil, 'users', 'secret')
          expect(result).to be_nil
        end
      end

      describe ':partial masking' do
        before { Dbviewer.configuration.pii_rules['users.username'] = :partial }

        it 'partially masks values' do
          result = described_class.mask_value('john_doe', 'users', 'username')
          expect(result).to eq('jo***oe')
        end

        it 'handles short values' do
          result = described_class.mask_value('ab', 'users', 'username')
          expect(result).to eq('ab')
        end

        it 'handles very short values' do
          result = described_class.mask_value('a', 'users', 'username')
          expect(result).to eq('a')
        end
      end
    end

    context 'with custom proc masking' do
      let(:custom_proc) { ->(value) { value ? "CUSTOM_#{value.upcase}" : value } }

      before { Dbviewer.configuration.pii_rules['users.field'] = custom_proc }

      it 'applies custom proc masking' do
        result = described_class.mask_value('test', 'users', 'field')
        expect(result).to eq('CUSTOM_TEST')
      end

      it 'handles nil values' do
        result = described_class.mask_value(nil, 'users', 'field')
        expect(result).to be_nil
      end
    end

    context 'with custom named masks' do
      let(:custom_mask) { ->(value) { value ? "CUSTOM_MASK: #{value}" : value } }

      before do
        Dbviewer.configuration.custom_pii_masks[:my_custom] = custom_mask
        Dbviewer.configuration.pii_rules['users.field'] = :my_custom
      end

      it 'applies custom named mask' do
        result = described_class.mask_value('test', 'users', 'field')
        expect(result).to eq('CUSTOM_MASK: test')
      end
    end

    context 'when masking function raises an error' do
      let(:failing_proc) { ->(value) { raise StandardError, 'Something went wrong' } }

      before do
        Dbviewer.configuration.pii_rules['users.field'] = failing_proc
        allow(Rails.logger).to receive(:warn)
      end

      it 'returns error placeholder' do
        result = described_class.mask_value('test', 'users', 'field')
        expect(result).to eq('***ERROR***')
      end

      it 'logs the error' do
        described_class.mask_value('test', 'users', 'field')
        expect(Rails.logger).to have_received(:warn).with(/PII masking failed/)
      end
    end
  end
end
