require 'rails_helper'

RSpec.shared_examples "application record" do
  it { should validate_presence_of(:device_created_at)}
  it { should validate_presence_of(:device_updated_at)}
end