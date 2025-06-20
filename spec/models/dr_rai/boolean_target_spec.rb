require "rails_helper"

RSpec.describe DrRai::BooleanTarget, type: :model do
  describe "type" do
    it 'should be "Boolean"' do
      expect(DrRai::BooleanTarget.new.type).to eq "DrRai::BooleanTarget"
    end
  end
end
