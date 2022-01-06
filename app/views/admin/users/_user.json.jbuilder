# frozen_string_literal: true

json.extract! user, :id, :full_name
json.teleconsultation_phone_number user.full_teleconsultation_phone_number
json.registration_facility user.registration_facility&.name
