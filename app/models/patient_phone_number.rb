class PatientPhoneNumber < ApplicationRecord
  belongs_to :patient
  belongs_to :phone_number
end