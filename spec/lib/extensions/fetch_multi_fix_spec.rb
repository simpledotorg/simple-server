# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rails cache fetch multi fix" do
  before do
    Rails.cache.clear
  end

  after do
    Rails.cache.clear
  end

  it "does not set new values without force option" do
    Rails.cache.fetch_multi("key1", "key2") { |key| "value set for #{key}" }
    expect(Rails.cache.read("key1")).to eq("value set for key1")
    expect(Rails.cache.read("key2")).to eq("value set for key2")

    Rails.cache.fetch_multi("key1", "key2") { |key| "forced value set for #{key}" }

    expect(Rails.cache.read("key1")).to eq("value set for key1")
    expect(Rails.cache.read("key2")).to eq("value set for key2")
  end

  it "sets all values if force option is provided" do
    Rails.cache.fetch_multi("key1", "key2") { |key| "value set for #{key}" }
    expect(Rails.cache.read("key1")).to eq("value set for key1")
    expect(Rails.cache.read("key2")).to eq("value set for key2")

    Rails.cache.fetch_multi("key1", "key2", force: true) { |key| "forced value set for #{key}" }

    expect(Rails.cache.read("key1")).to eq("forced value set for key1")
    expect(Rails.cache.read("key2")).to eq("forced value set for key2")
  end
end
