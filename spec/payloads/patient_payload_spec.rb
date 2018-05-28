require 'rails_helper'

describe PatientPayload, type: :model do
  describe "Associations" do
    it { should belong_to(:address) }
    it { should have_many(:phone_numbers) }
  end
end