require_dependency "seed/config"
require "factory_bot_rails"

module Seed
  class ProtocolSeeder
    include ConsoleLogger

    def self.call(*args)
      new(*args).call
    end

    def initialize(config:)
      @config = config
      @logger = Rails.logger.child(class: self.class.name)
    end

    attr_reader :config
    attr_reader :logger

    delegate :stdout, to: :config

    def call
      announce "Creating #{protocol_name} with drugs..."
      FactoryBot.create(:protocol, :with_tracked_drugs, name: protocol_name, follow_up_days: 28)
    end

    def protocol_name
      "#{Seed.seed_org.name} Protocol"
    end
  end
end
