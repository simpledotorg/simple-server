# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require_relative '../lib/tasks/scripts/create_admin_user'
require 'factory_bot_rails'
require 'faker'

NUM_OF_FACILITY_GROUPS = 1
NUM_OF_FACILITIES = 2
MAX_NUM_OF_USERS_PER_FACILITY = 2
NUM_OF_USERS_PER_FACILITY_FN = -> { rand(1..MAX_NUM_OF_USERS_PER_FACILITY) }

org = {
  :name => "IHCI"
}

facility_size_map = {
  "CH" => :large,
  "DH" => :large,
  "Hospital" => :large,
  "RH" => :large,
  "SDH" => :large,

  "CHC" => :medium,

  "MPHC" => :small,
  "PHC" => :small,
  "SAD" => :small,
  "Standalone" => :small,
  "UHC" => :small,
  "UPHC" => :small,
  "USAD" => :small,

  "HWC" => :community,
  "Village" => :community
}

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

#
# create organizations, protocols and protocol_drugs
#
organization = Organization.find_by(org) || FactoryBot.create(:organization, org)
protocol = Protocol.find_or_create_by!(protocol_data)
protocol_drugs_data.each { |drug_data| ProtocolDrug.find_or_create_by!(drug_data.merge(protocol_id: protocol.id)) }

facility_groups = (1..NUM_OF_FACILITY_GROUPS).to_a.map do
  facility_group_params = {
    organization: organization, protocol: protocol
  }

  FactoryBot.create(:facility_group, facility_group_params)
end

#
# create facility and facility_groups
#
facilities =
  facility_groups.map do |fg|
    (1..NUM_OF_FACILITIES).to_a.map do
      type = facility_size_map.keys.sample
      size = facility_size_map[type]

      FactoryBot.create(:facility,
                        facility_group_id: fg.id,
                        district: fg.name,
                        facility_type: type,
                        facility_size: size)
    end
  end.flatten

#
# create users
#
facilities.each do |facility|
  if facility.users.size < MAX_NUM_OF_USERS_PER_FACILITY
    role = rand > 0.1 ? ENV['ACTIVE_GENERATED_USER_ROLE'] : ENV['INACTIVE_GENERATED_USER_ROLE']
    FactoryBot.create_list(:user,
                           NUM_OF_USERS_PER_FACILITY_FN.call,
                           :with_phone_number_authentication,
                           registration_facility: facility,
                           organization: organization,
                           role: role)
  end
end

#
# create admin user
#
CreateAdminUser.create_owner('Admin User', 'admin@simple.org', ENV['GENERATED_ADMIN_PASSWORD'])

