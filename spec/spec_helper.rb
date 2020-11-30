require "simplecov" if ENV["CI"]
require "utils"
require "webmock/rspec"
require "sidekiq/testing"
require "flipper_helper"

WebMock.allow_net_connect!

RSpec.configure do |config|
  SimpleCov.start if ENV["CI"]

  config.include FlipperHelpers
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:each) do
    Rails.cache.clear
    RequestStore.clear!
  end

  config.before :all do
    # create a root region and persist across all tests (the root region is effectively a singleton)
    Region.root || Region.create!(name: "India", region_type: Region.region_types[:root], path: "india")
  end
end
