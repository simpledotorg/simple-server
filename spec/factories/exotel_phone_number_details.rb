FactoryBot.define do
  factory :exotel_phone_number_detail, class: 'ExotelPhoneNumberDetail' do
    patient_phone_number
    whitelist_status { ExotelPhoneNumberDetail.whitelist_statuses[:whitelist] }
    whitelist_status_valid_until { 1.month.from_now }
  end
end
