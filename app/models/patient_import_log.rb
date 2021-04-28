class PatientImportLog < ApplicationRecord
  belongs_to :user
  belongs_to :record, polymorphic: true
end
