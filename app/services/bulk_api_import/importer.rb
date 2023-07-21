class BulkApiImport::Importer
  def initialize(resource_list:)
    @resources = resource_list
  end

  def import
    @resources.each do |resource|
      resource_importer(resource).import
    end
  end

  def resource_importer(resource)
    case resource[:resourceType]
    when "Patient"
      BulkApiImport::FhirPatientImporter.new(resource)
    else
      throw NotImplementedError
    end
  end
end
