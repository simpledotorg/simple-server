# frozen_string_literal: true

namespace :dhis2 do
  desc "Export aggregate indicators for each facility to DHIS2"
  task export: :environment do
    DHIS2Exporter.export
  end
end
