class BulkApiImport::Importer
  def initialize(resource_list:)
    @resources = resource_list
  end

  def import
    @resources.each do |resource|
      resource_importer(resource).import if import_enabled?(resource)
    end
  end

  # TODO:
  # This method is a stopgap to ensure that our mock imports and real imports can coexist.
  # Once we have implemented all resource types, we should remove this method entirely.
  def import_enabled?(resource)
    %w[Patient].include?(resource[:resourceType])
  end

  def resource_importer(resource)
    case resource[:resourceType]
    when "Patient"
      BulkApiImport::FhirPatientImporter.new(resource)
    # when "Appointment"
    #   BulkApiImport::FhirAppointmentImporter.new(resource)
    # ...
    else
      throw NotImplementedError
    end
  end
end
