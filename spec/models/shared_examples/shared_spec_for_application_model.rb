require 'rails_helper'

RSpec.shared_examples 'a record that validates device timestamps' do
  it { should validate_presence_of(:device_created_at)}
  it { should validate_presence_of(:device_updated_at)}
end
