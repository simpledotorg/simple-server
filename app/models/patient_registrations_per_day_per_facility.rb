class PatientRegistrationsPerDayPerFacility < ApplicationRecord
  extend Reports::Refreshable

  belongs_to :facility
end
