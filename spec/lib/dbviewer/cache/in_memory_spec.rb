require 'rails_helper'
require 'timecop'
require 'dbviewer'

RSpec.describe Dbviewer::Cache::InMemory do
  let(:cache_expiry) { 300 } # 5 minutes
  let(:custom_expiry) { 60 } # 1 minute
  let(:cache) { described_class.new(cache_expiry) }
  let(:cache_key) { 'test_cache_key' }

  describe '#fetch' do
    context 'when cache is empty' do
      it 'executes the block and stores the result' do
        result = cache.fetch(cache_key) { 'test_data' }
        expect(result).to eq('test_data')
      end
    end

    context 'when cache has unexpired data' do
      it 'returns cached data without executing the block' do
        # First call stores data
        cache.fetch(cache_key) { 'test_data' }

        # Second call should return cached data
        result = cache.fetch(cache_key) { 'new_data' }
        expect(result).to eq('test_data')
      end
    end

    context 'when cache data is expired' do
      it 'executes the block with default expiry' do
        # First call stores data
        cache.fetch(cache_key) { 'test_data' }

        # Time travel past the expiry
        Timecop.travel(Time.now + cache_expiry + 1) do
          result = cache.fetch(cache_key) { 'new_data' }
          expect(result).to eq('new_data')
        end
      end

      it 'executes the block with custom expiry' do
        # First call stores data with custom expiry
        cache.fetch(cache_key, expires_in: custom_expiry) { 'test_data' }

        # Time travel past the custom expiry
        Timecop.travel(Time.now + custom_expiry + 1) do
          result = cache.fetch(cache_key, expires_in: custom_expiry) { 'new_data' }
          expect(result).to eq('new_data')
        end
      end

      it 'respects different expiry times for different entries' do
        # Create one entry with default expiry
        cache.fetch('default_expiry_key') { 'default_expiry_data' }

        # Create one entry with custom expiry
        cache.fetch('custom_expiry_key', expires_in: custom_expiry) { 'custom_expiry_data' }

        # Time travel past the custom expiry but not past default expiry
        Timecop.travel(Time.now + custom_expiry + 1) do
          # Custom expiry entry should be regenerated
          result_custom = cache.fetch('custom_expiry_key', expires_in: custom_expiry) { 'new_custom_data' }
          expect(result_custom).to eq('new_custom_data')

          # Default expiry entry should still be valid
          result_default = cache.fetch('default_expiry_key') { 'new_default_data' }
          expect(result_default).to eq('default_expiry_data')
        end
      end
    end
  end

  describe '#delete' do
    it 'removes entry from cache and returns its value' do
      # First store some data
      cache.fetch(cache_key) { 'test_data' }

      # Delete should return the cached value
      result = cache.delete(cache_key)
      expect(result).to eq('test_data')

      # Subsequent fetch should execute the block again
      new_result = cache.fetch(cache_key) { 'new_data' }
      expect(new_result).to eq('new_data')
    end

    it 'returns nil when key does not exist' do
      result = cache.delete('non_existent_key')
      expect(result).to be_nil
    end
  end

  describe 'private #cache_expired?' do
    it 'correctly identifies expired entries' do
      # We need to test the private method directly
      # First store some data
      cache.fetch(cache_key) { 'test_data' }

      # Get the cache entry
      cache_entry = cache.instance_variable_get(:@unified_cache)[cache_key]

      # Time travel to check expiry
      Timecop.travel(Time.now + cache_expiry - 1) do
        # Should not be expired yet
        expect(cache.send(:cache_expired?, cache_entry, cache_expiry)).to be false
      end

      Timecop.travel(Time.now + cache_expiry + 1) do
        # Should be expired now
        expect(cache.send(:cache_expired?, cache_entry, cache_expiry)).to be true
      end
    end
  end

  # Test initialization of InMemory cache
  describe '#initialize' do
    it 'initializes with default cache expiry' do
      cache = described_class.new
      expect(cache.instance_variable_get(:@cache_expiry)).to eq(300)
    end

    it 'initializes with custom cache expiry' do
      custom_cache = described_class.new(600)
      expect(custom_cache.instance_variable_get(:@cache_expiry)).to eq(600)
    end

    it 'initializes with empty unified cache' do
      expect(cache.instance_variable_get(:@unified_cache)).to eq({})
    end
  end
end
