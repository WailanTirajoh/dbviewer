require 'rails_helper'

RSpec.describe Dbviewer::Security::AccessControl do
  let(:config) do
    config = double('Configuration')
    allow(config).to receive(:access_control_mode).and_return(:whitelist)
    allow(config).to receive(:allowed_tables).and_return([ 'users', 'orders' ])
    allow(config).to receive(:blocked_tables).and_return([])
    allow(config).to receive(:blocked_columns).and_return({})
    config
  end

  let(:access_control) { described_class.new(config) }

  describe '#validate_query_table_access' do
    context 'with whitelist mode' do
      it 'allows queries that only access whitelisted tables' do
        sql = "SELECT * FROM users WHERE id = 1"
        expect(access_control.validate_query_table_access(sql)).to be true
      end

      it 'allows queries with multiple whitelisted tables' do
        sql = "SELECT * FROM users JOIN orders ON users.id = orders.user_id"
        expect(access_control.validate_query_table_access(sql)).to be true
      end

      it 'blocks queries that access non-whitelisted tables' do
        sql = "SELECT * FROM products WHERE category = 'electronics'"
        expect(access_control.validate_query_table_access(sql)).to be false
      end

      it 'blocks queries with mix of whitelisted and non-whitelisted tables' do
        sql = "SELECT * FROM users JOIN products ON users.favorite_product_id = products.id"
        expect(access_control.validate_query_table_access(sql)).to be false
      end

      it 'handles complex queries correctly' do
        sql = <<~SQL
          WITH active_users AS (
            SELECT * FROM users WHERE active = true
          )
          SELECT u.name, o.total
          FROM active_users u
          LEFT JOIN orders o ON u.id = o.user_id
          WHERE u.id IN (
            SELECT user_id FROM subscriptions WHERE status = 'active'
          )
        SQL
        # This should fail because 'subscriptions' is not in the whitelist
        expect(access_control.validate_query_table_access(sql)).to be false
      end
    end

    context 'with no access control' do
      let(:config) do
        config = double('Configuration')
        allow(config).to receive(:access_control_mode).and_return(:none)
        config
      end

      it 'allows all queries when access control is disabled' do
        sql = "SELECT * FROM any_table JOIN another_table ON any_table.id = another_table.ref_id"
        expect(access_control.validate_query_table_access(sql)).to be true
      end
    end
  end

  describe '#table_accessible?' do
    it 'correctly identifies whitelisted tables' do
      expect(access_control.table_accessible?('users')).to be true
      expect(access_control.table_accessible?('orders')).to be true
      expect(access_control.table_accessible?('products')).to be false
    end
  end

  describe '#filter_accessible_tables' do
    it 'filters tables based on whitelist' do
      all_tables = [ 'users', 'orders', 'products', 'categories' ]
      accessible = access_control.filter_accessible_tables(all_tables)
      expect(accessible).to contain_exactly('users', 'orders')
    end
  end

  describe 'SQL parser integration' do
    it 'uses the SQL parser to extract table names' do
      # Test that the access control properly delegates to the SQL parser
      sql = "SELECT u.name FROM users u JOIN orders o ON u.id = o.user_id"

      # Mock the SQL parser to verify it's being called
      sql_parser = instance_double(Dbviewer::Security::SqlParser)
      allow(Dbviewer::Security::SqlParser).to receive(:new).and_return(sql_parser)
      allow(sql_parser).to receive(:extract_table_names).with(sql).and_return([ 'users', 'orders' ])

      access_control_with_mock = described_class.new(config)
      result = access_control_with_mock.validate_query_table_access(sql)

      expect(sql_parser).to have_received(:extract_table_names).with(sql)
      expect(result).to be true
    end
  end

  describe '#access_violation_message' do
    it 'provides helpful error messages for whitelist violations' do
      message = access_control.access_violation_message('products')
      expect(message).to include("Table 'products' is not in the allowed tables list")
    end

    it 'provides general error message when no specific table is given' do
      message = access_control.access_violation_message
      expect(message).to include("Only the following tables are accessible: users, orders")
    end
  end
end
