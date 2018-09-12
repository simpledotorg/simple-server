FactoryBot.define do
  factory :audit_log do
    action { 'fetch' }
    auditable_type { 'Patient' }
    auditable_id { create(:patient).id }
    user
  end
end