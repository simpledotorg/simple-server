class Teleconsultation < ApplicationRecord
  belongs_to :patient
  belongs_to :facility
  belongs_to :requester, class_name: "User", foreign_key: :requester_id
  belongs_to :medical_officer, class_name: "User", foreign_key: :medical_officer_id
end
