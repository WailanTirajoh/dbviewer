require 'rails_helper'

RSpec.describe Dbviewer::FormattingHelper, type: :helper do
  let(:original_rules) { Dbviewer.configuration.pii_rules.dup }
  let(:original_enabled) { Dbviewer.configuration.enable_pii_masking }

  before do
    Dbviewer.configuration.pii_rules.clear
    Dbviewer.configuration.enable_pii_masking = true
  end

  after do
    Dbviewer.configuration.pii_rules = original_rules
    Dbviewer.configuration.enable_pii_masking = original_enabled
  end

  describe '#format_cell_value' do
    context 'without PII masking' do
      it 'formats cell values normally' do
        result = helper.format_cell_value('test_value')
        expect(result).to eq('test_value')
      end

      it 'handles nil values' do
        result = helper.format_cell_value(nil)
        expect(result).to eq('NULL')
      end
    end

    context 'with PII masking' do
      before do
        Dbviewer.configuration.pii_rules['users.email'] = :email
      end

      it 'applies PII masking when table and column are provided' do
        result = helper.format_cell_value('test@example.com', 'users', 'email')
        expect(result).to eq('te***@example.com')
      end

      it 'does not apply PII masking when table and column are not provided' do
        result = helper.format_cell_value('test@example.com')
        expect(result).to eq('test@example.com')
      end

      it 'does not apply PII masking for non-matching columns' do
        result = helper.format_cell_value('test@example.com', 'users', 'name')
        expect(result).to eq('test@example.com')
      end
    end

    context 'with date formatting and PII masking' do
      before do
        Dbviewer.configuration.pii_rules['users.created_at'] = ->(value) { 'MASKED_DATE' }
      end

      it 'applies PII masking before date formatting' do
        result = helper.format_cell_value('2023-01-01T10:00:00', 'users', 'created_at')
        expect(result).to eq('MASKED_DATE')
      end
    end

    context 'with JSON formatting and PII masking' do
      before do
        Dbviewer.configuration.pii_rules['users.metadata'] = :full_redact
      end

      it 'applies PII masking before JSON formatting' do
        json_value = '{"secret": "value"}'
        result = helper.format_cell_value(json_value, 'users', 'metadata')
        expect(result).to eq('***REDACTED***')
      end
    end
  end
end
