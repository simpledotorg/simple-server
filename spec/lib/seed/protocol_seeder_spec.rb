# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::ProtocolSeeder do
  it "creates a protocol and protocol drugs" do
    org_name = Seed.seed_org.name
    Seed::ProtocolSeeder.call(config: Seed::Config.new)

    protocol = Protocol.find_by(name: "#{org_name} Protocol")
    expect(protocol).to be_present
    expect(protocol.protocol_drugs.pluck(:name)).to include(
      "Amlodipine",
      "Telmisartan",
      "Losartan",
      "Hydrochlorothiazide",
      "Chlorthalidone"
    )
  end
end
