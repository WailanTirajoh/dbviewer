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
