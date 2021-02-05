require_dependency "seed/config"

module Seed
  class ProtocolSeederSeeder
    include ConsoleLogger

    def self.call(*args)
      new(*args).call
    end

    def initialize(config:)
      @config = config
      @logger = Rails.logger.child(class: self.class.name)
      announce "Starting #{self.class} with #{config.type} configuration"
    end

    attr_reader :config
    attr_reader :logger

    delegate :stdout, to: :config

    PROTOCOL_DRUGS = [
      {name: "Amlodipine", dosage: "5 mg", rxnorm_code: "329528", protocol: protocol, drug_category: :hypertension_ccb, stock_tracked: true},
      {name: "Amlodipine", dosage: "10 mg", rxnorm_code: "329526", protocol: protocol, drug_category: :hypertension_ccb, stock_tracked: true},
      {name: "Telmisartin", dosage: "40 mg", rxnorm_code: "316764", protocol: protocol, drug_category: :hypertension_arb, stock_tracked: true},
      {name: "Telmisartin", dosage: "80 mg", rxnorm_code: "316765", protocol: protocol, drug_category: :hypertension_arb, stock_tracked: true},
      {name: "Losartan", dosage: "50 mg", rxnorm_code: "979467", protocol: protocol, drug_category: :hypertension_arb, stock_tracked: true},
      {name: "Hydrochlorothiazide", dosage: "12.5 mg", rxnorm_code: "316047", protocol: protocol, drug_category: :hypertension_diuretic, stock_tracked: true},
      {name: "Hydrochlorothiazide", dosage: "25 mg", rxnorm_code: "316049", protocol: protocol, drug_category: :hypertension_diuretic, stock_tracked: true},
      {name: "Chlorthalidone", dosage: "12.5 mg", rxnorm_code: "331132", protocol: protocol, drug_category: :hypertension_diuretic, stock_tracked: true}
    ].freeze

    def call
      announce "Creating #{protocol_name}..."
      protocol = Protocol.create!(name: )

      announce "Creating protocol drugs for #{protocol_name}..."
      PROTOCOL_DRUGS.each do |attributes|
        ProtocolDrug.create!(attributes)
      end

      protocol
    end

    def protocol_name
      "#{Seed.seed_org.name} Protocol"
    end
  end
end
