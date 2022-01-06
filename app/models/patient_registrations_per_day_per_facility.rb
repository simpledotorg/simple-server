# frozen_string_literal: true

class PatientRegistrationsPerDayPerFacility < ApplicationRecord
  extend Reports::Refreshable

  belongs_to :facility
end
