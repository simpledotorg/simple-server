# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require_relative "../lib/tasks/scripts/create_admin_user"
require "factory_bot_rails"
require "faker"

NUM_OF_FACILITY_GROUPS = 4
MAX_NUM_OF_FACILITIES_PER_FACILITY_GROUP = 8
MAX_NUM_OF_USERS_PER_FACILITY = 2
ADMIN_USER_NAME = "Admin User"
ADMIN_USER_EMAIL = "admin@simple.org"

org = {
  name: "IHCI"
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
  name: "Simple Hypertension Protocol",
  follow_up_days: 30
}

protocol_drugs_data = [
  {
    name: "Amlodipine",
    dosage: "5 mg"
  },
  {
    name: "Amlodipine",
    dosage: "10 mg"
  },
  {
    name: "Telmisartan",
    dosage: "40 mg"
  },
  {
    name: "Telmisartan",
    dosage: "80 mg"
  },
  {
    name: "Chlorthalidone",
    dosage: "12.5 mg"
  },
  {
    name: "Chlorthalidone",
    dosage: "25 mg"
  }
]

#
# create organizations, protocols and protocol_drugs
#
Region.root || Region.create!(name: "India", region_type: Region.region_types[:root], path: "india")
organization = Organization.find_by(org) || FactoryBot.create(:organization, org)
protocol = Protocol.find_or_create_by!(protocol_data)
protocol_drugs_data.each { |drug_data| ProtocolDrug.find_or_create_by!(drug_data.merge(protocol_id: protocol.id)) }

NUM_OF_FACILITY_GROUPS.times do
  facility_group_params = {organization: organization, protocol: protocol}
  facility_group = FactoryBot.create(:facility_group, facility_group_params)

  (1..MAX_NUM_OF_FACILITIES_PER_FACILITY_GROUP).to_a.sample.times do
    type = facility_size_map.keys.sample
    size = facility_size_map[type]

    facility_attrs = {
      district: facility_group.name,
      facility_group_id: facility_group.id,
      facility_size: size,
      facility_type: type
    }
    facility = FactoryBot.create(:facility, :seed, facility_attrs)
    if facility.users.size < MAX_NUM_OF_USERS_PER_FACILITY
      role = rand > 0.1 ? ENV["SEED_GENERATED_ACTIVE_USER_ROLE"] : ENV["SEED_GENERATED_INACTIVE_USER_ROLE"]
      FactoryBot.create_list(:user, rand(1..MAX_NUM_OF_USERS_PER_FACILITY), :with_phone_number_authentication,
        registration_facility: facility,
        organization: organization,
        role: role)
    end
  end
end

#
# create admin user
#
unless EmailAuthentication.find_by_email(ADMIN_USER_EMAIL)
  CreateAdminUser.create_owner(ADMIN_USER_NAME, ADMIN_USER_EMAIL, ENV["SEED_GENERATED_ADMIN_PASSWORD"])
end
