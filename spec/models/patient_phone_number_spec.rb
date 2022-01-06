# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientPhoneNumber, type: :model do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "Default scope" do
    let!(:patient) { create(:patient, phone_numbers: []) }
    let!(:first_phone) { create(:patient_phone_number, patient: patient, device_created_at: 5.days.ago) }
    let!(:middle_phone) { create(:patient_phone_number, patient: patient, device_created_at: 2.days.ago) }
    let!(:last_phone) { create(:patient_phone_number, patient: patient, device_created_at: 1.day.ago) }

    describe ".first" do
      it "returns oldest device_created_at number" do
        expect(PatientPhoneNumber.first).to eq(first_phone)
      end
    end

    describe ".last" do
      it "returns newest device_created_at number" do
        expect(PatientPhoneNumber.last).to eq(last_phone)
      end
    end
  end

  describe "require_whitelisting" do
    let!(:patient) { create(:patient) }
    let!(:non_dnd_phone) { create(:patient_phone_number, patient: patient, dnd_status: false) }

    let!(:dnd_phone) { create(:patient_phone_number, patient: patient, dnd_status: true) }

    let!(:blackist_phone) do
      phone_number = create(:patient_phone_number, patient: patient, dnd_status: true)
      create(:exotel_phone_number_detail, patient_phone_number: phone_number, whitelist_status: "blacklist")
      phone_number
    end

    let!(:neutral_phone) do
      phone_number = create(:patient_phone_number, patient: patient, dnd_status: true)
      create(:exotel_phone_number_detail, patient_phone_number: phone_number, whitelist_status: "neutral")
      phone_number
    end

    let!(:valid_whitelist_phone) do
      phone_number = create(:patient_phone_number, patient: patient, dnd_status: true)
      create(:exotel_phone_number_detail, patient_phone_number: phone_number, whitelist_status: "whitelist", whitelist_status_valid_until: 3.days.from_now)
      phone_number
    end

    let!(:expired_whitelist_phone) do
      phone_number = create(:patient_phone_number, patient: patient, dnd_status: true)
      create(:exotel_phone_number_detail, patient_phone_number: phone_number, whitelist_status: "whitelist", whitelist_status_valid_until: 3.days.ago)
      phone_number
    end

    let!(:invalid_phone) { create(:patient_phone_number, patient: patient, phone_type: :invalid) }

    it "returns all the numbers that require whitelisting" do
      expect(PatientPhoneNumber.require_whitelisting)
        .to include(dnd_phone,
          neutral_phone,
          expired_whitelist_phone)

      expect(PatientPhoneNumber.require_whitelisting)
        .not_to include(non_dnd_phone,
          blackist_phone,
          valid_whitelist_phone,
          invalid_phone)
    end
  end

  describe "update_exotel_phone_number_detail" do
    let(:patient) { create(:patient) }
    let(:patient_phone_number) { create(:patient_phone_number, patient: patient) }
    let(:update_attributes) do
      {dnd_status: true,
       phone_type: "mobile",
       whitelist_status: "whitelist",
       whitelist_status_valid_until: 6.months.from_now}
    end
    it "update the phone number and it's exotel details if they exist" do
      create(:exotel_phone_number_detail, patient_phone_number: patient_phone_number)
      patient_phone_number.update_exotel_phone_number_detail(update_attributes)
      expect(patient_phone_number.dnd_status).to eq(update_attributes[:dnd_status])
      expect(patient_phone_number.phone_type).to eq(update_attributes[:phone_type])
      expect(patient_phone_number.exotel_phone_number_detail.whitelist_status).to eq(update_attributes[:whitelist_status])
      expect(patient_phone_number.exotel_phone_number_detail.whitelist_status_valid_until).to eq(update_attributes[:whitelist_status_valid_until])
    end

    it "update the phone number and creates it's exotel details if they do not exist" do
      expect {
        patient_phone_number.update_exotel_phone_number_detail(update_attributes)
      }.to change(ExotelPhoneNumberDetail.where(patient_phone_number: patient_phone_number), :count)
        .from(0).to(1)
    end
  end

  describe "localized_phone_number" do
    include_examples "phone_number_localizable"
  end
end
