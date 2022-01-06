# frozen_string_literal: true

require "rails_helper"

RSpec.describe SimpleServerExtensions do
  it "has a git ref method" do
    expected_ref = `git rev-parse HEAD`.chomp
    expect(SimpleServer.git_ref).to eq(expected_ref)
  end

  it "knows the SIMPLE_SERVER_ENV" do
    expect(SimpleServer.env).to eq("test")
  end

  it "can ask about env like Rails.env" do
    expect(SimpleServer.env.test?).to be true
    expect(SimpleServer.env.development?).to be false
    expect(SimpleServer.env.production?).to be false
    expect(SimpleServer.env.anything?).to be false
  end
end
