require 'rails_helper'

RSpec.shared_examples 'a record that can be synced remotely' do
  it { should validate_presence_of(:device_created_at)}
  it { should validate_presence_of(:device_updated_at)}
end
