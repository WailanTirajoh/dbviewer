require 'spec_helper'
require 'rails_helper'

RSpec.describe Dbviewer::Logger do
  let(:logger) { Class.new(described_class).instance }
  before(:each) { logger.clear }

  describe "#stats" do
    it "initiate with empty data" do
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

    context 'when logs are available' do
      # TODO:
      # - add tests when logs are available, should show stats with logs
      # - add tests when logs are available, should show based on filtered value stats with logs
      # - when logs are availble, should be able to clear and ensure logs are empty
    end
  end
end
