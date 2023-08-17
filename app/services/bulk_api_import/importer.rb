class BulkApiImport::Importer
  def initialize(resource_list:)
    @resources = resource_list
  end

  IMPORTERS = {
    "Patient" => BulkApiImport::FhirPatientImporter,
    "Appointment" => BulkApiImport::FhirAppointmentImporter,
    "Observation" => BulkApiImport::FhirObservationImporter,
    "MedicationRequest" => BulkApiImport::FhirMedicationRequestImporter,
    "Condition" => BulkApiImport::FhirConditionImporter
  }

  def import
    @resources.each do |resource|
      resource_importer(resource).import
    end
  end

  def resource_importer(resource)
    importer = IMPORTERS[resource[:resourceType]]
    raise NotImplementedError unless importer.present?
    importer.new(resource)
  end
end
