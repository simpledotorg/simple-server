class BulkApiImport::Importer
  def initialize(resource_list:)
    @resources = resource_list
  end

  IMPORTERS = {
    "Patient" => BulkApiImport::FhirPatientImporter,
    "Appointment" => BulkApiImport::FhirAppointmentImporter,
    "Observation" => BulkApiImport::FhirObservationImporter,
    "MedicationRequest" => BulkApiImport::FhirMedicationRequestImporter
  }

  def import
    @resources.each do |resource|
      resource_importer(resource).import if import_enabled?(resource)
    end
  end

  # TODO:
  # This method is a stopgap to ensure that our mock imports and real imports can coexist.
  # Once we have implemented all resource types, we should remove this method entirely.
  def import_enabled?(resource)
    IMPORTERS[resource[:resourceType]].present?
  end

  def resource_importer(resource)
    importer = IMPORTERS[resource[:resourceType]]
    raise NotImplementedError unless importer.present?
    importer.new(resource)
  end
end
