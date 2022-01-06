# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExotelPhoneNumberDetail, type: :model do
  describe "Associations" do
    it { should belong_to(:patient_phone_number) }
  end

  describe "Validations" do
    subject { create(:exotel_phone_number_detail) }
    it { should validate_uniqueness_of(:patient_phone_number) }
  end
end
