FactoryBot.define do
  factory :audit_log do
    action { 'fetch' }
    auditable_type { 'Patient' }
    auditable_id { create(:patient).id }
    user { create(:master_user, :with_phone_number_authentication)}
  end
end