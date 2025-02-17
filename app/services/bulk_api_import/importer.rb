class BulkApiImport::Importer
  def initialize(resource_list:, organization_id:)
    @resources = resource_list
    @organization_id = organization_id
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
      resource_importer(resource, @organization_id).import
    end
  end

  def resource_importer(resource, organization_id)
    importer = IMPORTERS[resource[:resourceType]]
    raise NotImplementedError unless importer.present?
    importer.new(resource: resource, organization_id: organization_id)
  end
end
