# frozen_string_literal: true

class PatientImportJob < ApplicationJob
  def perform(params:, facility:, admin:)
    PatientImport::Importer.new(params: params, facility: facility, admin: admin).import
  end
end
