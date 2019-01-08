FactoryBot.define do
  factory :admin_access_control do
    id { SecureRandom.uuid }
    admin
    access_controllable { association :facility_group }
  end
end