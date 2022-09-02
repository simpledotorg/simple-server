require "simplecov" if ENV["CI"]
require "utils"
require "webmock/rspec"
require "sidekiq/testing"
require "flipper_helper"
require "reporting_helpers"
require "capybara/rspec"

WebMock.allow_net_connect!

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|
  SimpleCov.start if ENV["CI"]
  config.include FlipperHelpers
  config.include ReportingHelpers, reporting_spec: true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # Rendering views in controller specs adds significant overhead and time - so sometimes it is useful to
  # only render_views on CI, especially if you are using guard and re-running focused specs.
  # For example, on an iMac Pro it takes about 2.8 seconds to run a single controller spec w/o views, and 6 seconds to run w/ views.
  def render_views_on_ci
    render_views if ENV["CI"]
  end

  if ENV["CI"]
    config.before(:example, :focus) do
      fail "This example was committed to CI with `:focus` turned on. Please remove any focus specs to make sure all tests run on CI"
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

# Provide an easy way to convert a date string to a month Period
# for example "December 2019".to_period
module StringToPeriod
  refine String do
    def to_period
      to_date.to_period
    end
  end
end
