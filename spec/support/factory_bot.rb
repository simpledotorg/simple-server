# frozen_string_literal: true

RSpec.configure do |config|
  FactoryBot.use_parent_strategy = false

  config.include FactoryBot::Syntax::Methods
end
