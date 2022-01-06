# frozen_string_literal: true

FactoryBot.define do
  factory :exotel_phone_number_detail, class: "ExotelPhoneNumberDetail" do
    transient do
      status { ExotelPhoneNumberDetail.whitelist_statuses[:whitelist] }
    end

    patient_phone_number
    whitelist_status { status }
    whitelist_status_valid_until { 1.month.from_now }
  end
end
