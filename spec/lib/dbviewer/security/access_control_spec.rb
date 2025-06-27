require 'rails_helper'

RSpec.describe Dbviewer::Security::AccessControl do
  let(:config) { Dbviewer::Configuration.new }
  let(:access_control) { described_class.new(config) }

  describe 'table access control' do
    context 'when access control mode is :none' do
      before { config.access_control_mode = :none }

      it 'allows access to any table' do
        expect(access_control.table_accessible?('users')).to be true
        expect(access_control.table_accessible?('admin_users')).to be true
      end
    end

    context 'when access control mode is :whitelist' do
      before do
        config.access_control_mode = :whitelist
        config.allowed_tables = [ 'users', 'orders' ]
      end

      it 'allows access only to whitelisted tables' do
        expect(access_control.table_accessible?('users')).to be true
        expect(access_control.table_accessible?('orders')).to be true
        expect(access_control.table_accessible?('admin_users')).to be false
        expect(access_control.table_accessible?('sensitive_data')).to be false
      end

      it 'filters table lists correctly' do
        all_tables = [ 'users', 'orders', 'admin_users', 'sensitive_data' ]
        accessible_tables = access_control.filter_accessible_tables(all_tables)
        expect(accessible_tables).to eq([ 'users', 'orders' ])
      end
    end

    context 'when access control mode is :blacklist' do
      before do
        config.access_control_mode = :blacklist
        config.blocked_tables = [ 'admin_users', 'sensitive_data' ]
      end

      it 'blocks access to blacklisted tables' do
        expect(access_control.table_accessible?('users')).to be true
        expect(access_control.table_accessible?('orders')).to be true
        expect(access_control.table_accessible?('admin_users')).to be false
        expect(access_control.table_accessible?('sensitive_data')).to be false
      end
    end
  end

  describe 'column access control' do
    before do
      config.blocked_columns = {
        'users' => [ 'password_digest', 'api_key' ],
        'orders' => [ 'internal_notes' ]
      }
    end

    it 'filters blocked columns from accessible columns' do
      all_columns = [ 'id', 'name', 'email', 'password_digest', 'api_key' ]
      accessible_columns = access_control.filter_accessible_columns('users', all_columns)
      expect(accessible_columns).to eq([ 'id', 'name', 'email' ])
    end

    it 'returns all columns for tables without blocked columns' do
      all_columns = [ 'id', 'name', 'category' ]
      accessible_columns = access_control.filter_accessible_columns('products', all_columns)
      expect(accessible_columns).to eq([ 'id', 'name', 'category' ])
    end
  end

  describe 'SQL query validation' do
    before do
      config.access_control_mode = :whitelist
      config.allowed_tables = [ 'users', 'orders' ]
    end

    it 'allows queries on accessible tables' do
      sql = 'SELECT * FROM users WHERE id = 1'
      expect(access_control.validate_query_table_access(sql)).to be true
    end

    it 'blocks queries on inaccessible tables' do
      sql = 'SELECT * FROM admin_users WHERE id = 1'
      expect(access_control.validate_query_table_access(sql)).to be false
    end

    it 'allows queries with joins on accessible tables' do
      sql = 'SELECT u.*, o.* FROM users u JOIN orders o ON u.id = o.user_id'
      expect(access_control.validate_query_table_access(sql)).to be true
    end

    it 'blocks queries with joins involving inaccessible tables' do
      sql = 'SELECT u.*, a.* FROM users u JOIN admin_users a ON u.id = a.user_id'
      expect(access_control.validate_query_table_access(sql)).to be false
    end
  end

  describe 'access violation messages' do
    context 'in whitelist mode' do
      before do
        config.access_control_mode = :whitelist
        config.allowed_tables = [ 'users', 'orders' ]
      end

      it 'provides appropriate error message' do
        message = access_control.access_violation_message('admin_users')
        expect(message).to include("Table 'admin_users' is not in the allowed tables list")
      end
    end

    context 'in blacklist mode' do
      before do
        config.access_control_mode = :blacklist
        config.blocked_tables = [ 'admin_users' ]
      end

      it 'provides appropriate error message' do
        message = access_control.access_violation_message('admin_users')
        expect(message).to include("Table 'admin_users' is blocked from access")
      end
    end
  end
end
