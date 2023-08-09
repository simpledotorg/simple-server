require "dhis2"
class Dhis2TrackerDataExporter
  def self.configure
    Dhis2.configure do |config|
      config.url = "http://localhost:8080"
      config.user = "admin"
      config.password = "district"
      config.version = "2.40.0-rc"
    end
  end

  def self.execute
    self.configure

    # self.import(path: "tracker/enrollments", query_params: {orgUnit: "DiszpKrYNg8", program: "pMIglSEqPGS"})
    self.export(path: "tracker", payload: {
      trackedEntities: [
        {
          orgUnit: "DiszpKrYNg8",
          trackedEntityType: "nEenWmSyUEp",
          enrollments: [
            {
              program: "pMIglSEqPGS"
            }
          ]
        }
      ]
    })
  end

  def self.export(path:, payload:)
    Dhis2.client.post(path: path, payload: payload)
  end

  def self.import(path:, query_params: {})
    Dhis2.client.get(path: path, query_params: query_params)
  end
end
