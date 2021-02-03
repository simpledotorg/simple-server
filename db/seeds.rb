# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require_relative "../lib/tasks/scripts/create_admin_user"

Seed::Runner.call

# TODO move over this protocal drug data to new seed lib
# protocol_data = {
#   name: "Simple Hypertension Protocol",
#   follow_up_days: 30
# }

# protocol_drugs_data = [
#   {
#     name: "Amlodipine",
#     dosage: "5 mg"
#   },
#   {
#     name: "Amlodipine",
#     dosage: "10 mg"
#   },
#   {
#     name: "Telmisartan",
#     dosage: "40 mg"
#   },
#   {
#     name: "Telmisartan",
#     dosage: "80 mg"
#   },
#   {
#     name: "Chlorthalidone",
#     dosage: "12.5 mg"
#   },
#   {
#     name: "Chlorthalidone",
#     dosage: "25 mg"
#   }
# ]
