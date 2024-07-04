class BulkApiImportJob < ApplicationJob
  def perform(resources:, organization_id:)
    BulkApiImport::Importer.new(resource_list: resources, organization_id: organization_id).import
  end
end
