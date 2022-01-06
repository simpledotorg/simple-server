# frozen_string_literal: true

module LoggerHelper
  def logger
    Rails.logger
  end
end

RSpec.configure do |config|
  config.include LoggerHelper
end
