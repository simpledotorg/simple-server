require "rails_helper"

RSpec.describe BsnlDeliveryDetail, type: :model do
  describe "Associations" do
    it { should have_one(:communication) }
  end
end
