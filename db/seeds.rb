# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require_relative '../lib/tasks/scripts/create_admin_user'

NUMBER_OF_USERS_PER_FACILITY = 2
GENERATED_USER_ROLE = 'Seeded'

org = {:name => "IHCI"}

facilities =
  [{:name => "HWC Gulab Garh", :district => "Bathinda", :state => "Punjab", :country => "India", :facility_type => "HWC", :enable_diabetes_management => false, :facility_size => "community"},
   {:name => "HWC Gurdaspur", :district => "Hoshiarpur", :state => "Punjab", :country => "India", :facility_type => "HWC", :enable_diabetes_management => true, :facility_size => "community"},
   {:name => "CHC Nathana", :district => "Bathinda", :state => "Punjab", :country => "India", :facility_type => "CHC", :enable_diabetes_management => true, :facility_size => "medium"},
   {:name => "HWC Velang", :district => "Satara", :state => "Maharashtra", :country => "India", :facility_type => "HWC", :enable_diabetes_management => false, :facility_size => "community"},
   {:name => "PHC Chulhad HWC Temni", :district => "Bhandara", :state => "Maharashtra", :country => "India", :facility_type => "HWC", :enable_diabetes_management => true, :facility_size => "community"},
   {:name => "HWC Darshopur", :district => "Pathankot", :state => "Punjab", :country => "India", :facility_type => "HWC", :enable_diabetes_management => false, :facility_size => "community"},
   {:name => "CHC Jhunir", :district => "Mansa", :state => "Punjab", :country => "India", :facility_type => "CHC", :enable_diabetes_management => false, :facility_size => "medium"},
   {:name => "HWC Pipri Girad", :district => "Wardha", :state => "Maharashtra", :country => "India", :facility_type => "HWC", :enable_diabetes_management => false, :facility_size => "community"},
   {:name => "PHC Chakowal", :district => "Hoshiarpur", :state => "Punjab", :country => "India", :facility_type => "PHC", :enable_diabetes_management => true, :facility_size => "small"},
   {:name => "Hindusabha Hospital", :district => "N Ward", :state => "Maharashtra", :country => "India", :facility_type => "Hospital", :enable_diabetes_management => false, :facility_size => "large"},
   {:name => "Dr. Israr Shaikh", :district => "G North", :state => "Maharashtra", :country => "India", :facility_type => "Standalone", :enable_diabetes_management => false, :facility_size => "small"},
   {:name => "CHC Dera Baba Nanak", :district => "Gurdaspur", :state => "Punjab", :country => "India", :facility_type => "CHC", :enable_diabetes_management => false, :facility_size => "medium"},
   {:name => "PHC Parule", :district => "Sindhudurg", :state => "Maharashtra", :country => "India", :facility_type => "PHC", :enable_diabetes_management => false, :facility_size => "small"},
   {:name => "HWC Ludha Munda", :district => "Gurdaspur", :state => "Punjab", :country => "India", :facility_type => "HWC", :enable_diabetes_management => true, :facility_size => "community"},
   {:name => "PHC Palashi Koregaon", :district => "Satara", :state => "Maharashtra", :country => "India", :facility_type => "PHC", :enable_diabetes_management => false, :facility_size => "small"},
   {:name => "HWC Chowkul", :district => "Sindhudurg", :state => "Maharashtra", :country => "India", :facility_type => "HWC", :enable_diabetes_management => false, :facility_size => "community"},
   {:name => "HWC Ranand", :district => "Satara", :state => "Maharashtra", :country => "India", :facility_type => "HWC", :enable_diabetes_management => false, :facility_size => "community"},
   {:name => "PHC Biroke Kalan", :district => "Mansa", :state => "Punjab", :country => "India", :facility_type => "PHC", :enable_diabetes_management => true, :facility_size => "small"},
   {:name => "PHC Shakti Dehra", :district => "Chamba", :state => "Himachal Pradesh", :country => "India", :facility_type => "PHC", :enable_diabetes_management => false, :facility_size => "medium"},
   {:name => "HWC Behman Diwana", :district => "Bathinda", :state => "Punjab", :country => "India", :facility_type => "HWC", :enable_diabetes_management => false, :facility_size => "community"}]

protocol_data = {
  name: 'Simple Hypertension Protocol',
  follow_up_days: 30
}

protocol_drugs_data = [
  {
    name: 'Amlodipine',
    dosage: '5 mg'
  },
  {
    name: 'Amlodipine',
    dosage: '10 mg'
  },
  {
    name: 'Telmisartan',
    dosage: '40 mg'
  },
  {
    name: 'Telmisartan',
    dosage: '80 mg'
  },
  {
    name: 'Chlorthalidone',
    dosage: '12.5 mg'
  },
  {
    name: 'Chlorthalidone',
    dosage: '25 mg'
  }
]

organization = Organization.find_by(org) || FactoryBot.create(:organization, org)
protocol = Protocol.find_or_create_by(protocol_data)
protocol_drugs_data.each { |drug_data| ProtocolDrug.find_or_create_by(drug_data.merge(protocol_id: protocol.id)) }


facilities.each do |facility_data|
  facility_group_params = {name: facility_data[:district], organization: organization}
  facility_group =
    FacilityGroup.find_by(facility_group_params) || FactoryBot.create(:facility_group,
                                                                      facility_group_params.merge(protocol: protocol))

  facility_params = facility_data.merge(facility_group_id: facility_group.id)
  facility = Facility.find_by(facility_data.merge(facility_params)) || FactoryBot.create(:facility, facility_params)

  FactoryBot.create_list(:user,
                         NUMBER_OF_USERS_PER_FACILITY,
                         :with_phone_number_authentication,
                         registration_facility: facility,
                         organization: organization,
                         role: PopulateFakeDataJob::FAKE_DATA_USER_ROLE) if facility.users.size < NUMBER_OF_USERS_PER_FACILITY
end

CreateAdminUser.create_owner('Admin User', 'admin@simple.org', 'password')
