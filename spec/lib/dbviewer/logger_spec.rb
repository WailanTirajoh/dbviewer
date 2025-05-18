require 'spec_helper'
require 'rails_helper'
# require '../../../lib/dbviewer'

RSpec.describe Dbviewer::Logger do
  let(:logger) { Class.new(described_class).instance }

  describe "#stats" do
    context 'when mode is :file' do
      it "show list of stats" do
        expect(logger.stats).to eq(
          {
            total_count: 0,
            total_duration_ms: 0,
            avg_duration_ms: 0,
            max_duration_ms: 0,
            tables_queried: {},
            potential_n_plus_1: [],
            slowest_queries: [],
            request_count: 0,
            avg_queries_per_request: 0,
            max_queries_per_request: 0
          }
        )
      end

      context 'when there are queries' do
        let(:query) { "SELECT * FROM users WHERE id = ?" }
        let(:duration) { 100 }
        let(:binds) { [ 1 ] }
        let(:event) do
          # Create event with consistent timing
          start_time = Time.now
          end_time = start_time + (duration / 1000.0)  # convert ms to seconds
          
          ActiveSupport::Notifications::Event.new(
            "sql.active_record",
            start_time,
            end_time,
            1,
            {
              sql: query,
              name: "SQL",
              binds: binds,
              caller: caller
            }
          )
        end

        it "updates the stats" do
          # Reset the logger instance to ensure a clean test
          described_class.instance_variable_set(:@instance, nil)
          
          # Create test doubles
          memory_storage = instance_double(Dbviewer::Storage::InMemoryStorage)
          allow(memory_storage).to receive(:add)
          
          # Fixed timestamp for predictable test results
          current_time = Time.new(2023, 1, 1, 12, 0, 0)
          request_id = "req-#{current_time.to_i}-1"
          
          # Set up the query that will be returned by the storage
          allow(memory_storage).to receive(:all).and_return([
            {
              sql: query,
              name: "SQL",
              timestamp: current_time,
              duration_ms: duration,
              binds: binds,
              request_id: request_id,
              thread_id: "123456"
            }
          ])
          
          # Set up configuration
          allow(Dbviewer.configuration).to receive(:query_logging_mode).and_return(:memory)
          allow(Dbviewer::Storage::InMemoryStorage).to receive(:new).and_return(memory_storage)
          
          # Allow the analyzer to work properly
          allow(Dbviewer::QueryParser).to receive(:extract_tables).and_return(["users"])
          
          # Create test instance with our doubles
          logger = described_class.instance
          
          # Manually process the event to update stats
          # We need to stub Time.now for consistency
          allow(Time).to receive(:now).and_return(current_time)
          logger.send(:process_sql_event, event)
          
          # Verify stats are updated
          stats = logger.stats
          expect(stats[:total_count]).to eq(1)
          expect(stats[:total_duration_ms]).to eq(duration)
          expect(stats[:avg_duration_ms]).to eq(duration)
          expect(stats[:max_duration_ms]).to eq(duration)
          expect(stats[:tables_queried]).to include("users")
          expect(stats[:request_count]).to eq(1)
        end
      end
    end

    context 'when mode is :memory' do
      before do
        allow(Dbviewer.configuration).to receive(:query_logging_mode).and_return(:memory)
        allow(logger).to receive(:setup_storage)
        allow(logger).to receive(:subscribe_to_sql_notifications)
      end

      it "show list of stats" do
        expect(logger.stats).to eq(
          {
            total_count: 0,
            total_duration_ms: 0,
            avg_duration_ms: 0,
            max_duration_ms: 0,
            tables_queried: {},
            potential_n_plus_1: [],
            slowest_queries: [],
            request_count: 0,
            avg_queries_per_request: 0,
            max_queries_per_request: 0
          }
        )
      end
    end
  end
end
