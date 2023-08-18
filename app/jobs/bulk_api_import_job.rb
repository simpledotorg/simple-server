class BulkApiImportJob < ApplicationJob
  def perform(resources:)
    BulkApiImport::Importer.new(resource_list: resources).import
  end
end
