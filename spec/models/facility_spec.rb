require 'rails_helper'

RSpec.describe Facility, type: :model do
  describe "Validations" do
    it { should validate_presence_of(:name)}
    it { should validate_presence_of(:district)}
    it { should validate_presence_of(:state)}
    it { should validate_presence_of(:country)}
  end
end
