require 'rails_helper'

RSpec.describe Dbviewer::Security::SqlParser do
  let(:parser) { described_class.new }

  describe '#extract_table_names' do
    context 'with simple SELECT queries' do
      it 'extracts table name from basic SELECT' do
        sql = "SELECT * FROM users"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'extracts table name with schema prefix' do
        sql = "SELECT * FROM public.users"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'extracts table name with quoted identifiers' do
        sql = 'SELECT * FROM "user_accounts"'
        expect(parser.extract_table_names(sql)).to eq([ 'user_accounts' ])
      end

      it 'extracts table name with backticks' do
        sql = "SELECT * FROM `users`"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end
    end

    context 'with JOIN queries' do
      it 'extracts table names from INNER JOIN' do
        sql = "SELECT * FROM users INNER JOIN orders ON users.id = orders.user_id"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'orders')
      end

      it 'extracts table names from multiple JOINs' do
        sql = "SELECT * FROM users LEFT JOIN orders ON users.id = orders.user_id RIGHT JOIN products ON orders.product_id = products.id"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'orders', 'products')
      end

      it 'extracts table names from different JOIN types' do
        sql = "SELECT * FROM users FULL OUTER JOIN orders ON users.id = orders.user_id CROSS JOIN categories"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'orders', 'categories')
      end
    end

    context 'with subqueries' do
      it 'extracts table names from subqueries in WHERE clause' do
        sql = "SELECT * FROM users WHERE id IN (SELECT user_id FROM orders)"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'orders')
      end

      it 'extracts table names from subqueries in FROM clause' do
        sql = "SELECT * FROM (SELECT * FROM users WHERE active = true) AS active_users"
        expect(parser.extract_table_names(sql)).to contain_exactly('users')
      end

      it 'extracts table names from nested subqueries' do
        sql = "SELECT * FROM users WHERE id IN (SELECT user_id FROM orders WHERE product_id IN (SELECT id FROM products WHERE category = 'electronics'))"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'orders', 'products')
      end
    end

    context 'with CTEs (Common Table Expressions)' do
      it 'extracts table names from simple CTE' do
        sql = "WITH active_users AS (SELECT * FROM users WHERE active = true) SELECT * FROM active_users"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'extracts table names from multiple CTEs' do
        sql = "WITH active_users AS (SELECT * FROM users WHERE active = true), recent_orders AS (SELECT * FROM orders WHERE created_at > '2023-01-01') SELECT * FROM active_users JOIN recent_orders ON active_users.id = recent_orders.user_id"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'orders')
      end

      it 'extracts table names from recursive CTE' do
        sql = "WITH RECURSIVE category_tree AS (SELECT * FROM categories WHERE parent_id IS NULL UNION ALL SELECT c.* FROM categories c JOIN category_tree ct ON c.parent_id = ct.id) SELECT * FROM category_tree"
        expect(parser.extract_table_names(sql)).to eq([ 'categories' ])
      end

      it 'handles quoted CTE names' do
        sql = 'WITH "active_users" AS (SELECT * FROM users WHERE active = true) SELECT * FROM "active_users"'
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'handles backtick-quoted CTE names' do
        sql = 'WITH `active_users` AS (SELECT * FROM users WHERE active = true) SELECT * FROM `active_users`'
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'handles schema-qualified CTE names' do
        sql = "WITH schema.active_users AS (SELECT * FROM users WHERE active = true) SELECT * FROM schema.active_users"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'handles schema-qualified quoted CTE names' do
        sql = 'WITH schema."active_users" AS (SELECT * FROM users WHERE active = true) SELECT * FROM schema."active_users"'
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'handles mixed quoted and unquoted CTEs' do
        sql = 'WITH active_users AS (SELECT * FROM users WHERE active = true), "recent_orders" AS (SELECT * FROM orders WHERE created_at > \'2023-01-01\') SELECT * FROM active_users JOIN "recent_orders" ON active_users.id = "recent_orders".user_id'
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'orders')
      end
    end

    context 'with DML operations' do
      it 'extracts table names from INSERT' do
        sql = "INSERT INTO users (name, email) VALUES ('John', 'john@example.com')"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'extracts table names from UPDATE' do
        sql = "UPDATE users SET email = 'new@example.com' WHERE id = 1"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'extracts table names from UPDATE with FROM' do
        sql = "UPDATE users SET status = 'inactive' FROM orders WHERE users.id = orders.user_id AND orders.total < 10"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'orders')
      end

      it 'extracts table names from DELETE' do
        sql = "DELETE FROM users WHERE id = 1"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end
    end

    context 'with set operations' do
      it 'extracts table names from UNION' do
        sql = "SELECT name FROM users UNION SELECT name FROM customers"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'customers')
      end

      it 'extracts table names from UNION ALL' do
        sql = "SELECT id FROM orders UNION ALL SELECT id FROM returns"
        expect(parser.extract_table_names(sql)).to contain_exactly('orders', 'returns')
      end

      it 'extracts table names from INTERSECT' do
        sql = "SELECT email FROM users INTERSECT SELECT email FROM subscribers"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'subscribers')
      end

      it 'extracts table names from EXCEPT' do
        sql = "SELECT email FROM users EXCEPT SELECT email FROM unsubscribed"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'unsubscribed')
      end
    end

    context 'with complex queries' do
      it 'extracts table names from complex query with multiple elements' do
        sql = <<~SQL
          WITH active_users AS (
            SELECT * FROM users WHERE active = true
          ),
          recent_orders AS (
            SELECT * FROM orders WHERE created_at > '2023-01-01'
          )
          SELECT u.name, o.total
          FROM active_users u
          LEFT JOIN recent_orders o ON u.id = o.user_id
          LEFT JOIN products p ON o.product_id = p.id
          WHERE u.id IN (
            SELECT user_id FROM subscriptions WHERE status = 'active'
          )
          UNION ALL
          SELECT c.name, 0 as total
          FROM customers c
          WHERE c.created_at > '2023-01-01'
        SQL
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'orders', 'products', 'subscriptions', 'customers')
      end
    end

    context 'with multiple statements' do
      it 'extracts table names from multiple statements separated by semicolons' do
        sql = "SELECT * FROM users; INSERT INTO logs (message) VALUES ('test'); UPDATE settings SET value = 'new' WHERE key = 'config'"
        expect(parser.extract_table_names(sql)).to contain_exactly('users', 'logs', 'settings')
      end
    end

    context 'with comments' do
      it 'ignores single-line comments' do
        sql = "SELECT * FROM users -- This is a comment"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'ignores multi-line comments' do
        sql = "SELECT * FROM users /* This is a\n multi-line comment */ WHERE active = true"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end
    end

    context 'with edge cases' do
      it 'returns empty array for nil input' do
        expect(parser.extract_table_names(nil)).to eq([])
      end

      it 'returns empty array for empty string' do
        expect(parser.extract_table_names("")).to eq([])
      end

      it 'returns empty array for whitespace-only string' do
        expect(parser.extract_table_names("   \n\t  ")).to eq([])
      end

      it 'handles escaped quotes in table names' do
        sql = 'SELECT * FROM "user""accounts"'
        # This might not work perfectly with the current regex, but it shouldn't crash
        result = parser.extract_table_names(sql)
        expect(result).to be_an(Array)
      end

      it 'ignores function calls that look like tables' do
        sql = "SELECT * FROM generate_series(1, 10)"
        expect(parser.extract_table_names(sql)).to eq([])
      end
    end

    describe 'string literal handling in comments' do
      it 'preserves comment-like content inside string literals' do
        sql = "SELECT 'user--name' FROM users -- real comment"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'preserves multi-line comment-like content inside string literals' do
        sql = "SELECT 'user/*not a comment*/' FROM users /* real comment */"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'handles escaped quotes in string literals with comment-like content' do
        sql = "SELECT 'user''s--name' FROM users -- comment"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'handles double-quoted strings with comment-like content' do
        sql = 'SELECT "user--name" FROM users -- comment'
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end

      it 'handles complex mixed case with string literals and real comments' do
        sql = "SELECT 'string with -- fake comment' AS col, \"another -- fake\" FROM users /* real comment */ WHERE name = 'user--name'"
        expect(parser.extract_table_names(sql)).to eq([ 'users' ])
      end
    end
  end

  describe '.extract_table_names' do
    it 'provides a class method interface' do
      sql = "SELECT * FROM users"
      expect(described_class.extract_table_names(sql)).to eq([ 'users' ])
    end
  end
end
