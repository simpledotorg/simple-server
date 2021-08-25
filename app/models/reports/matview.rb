module Reports
  class Matview < Reports::View
    def self.materialized?
      true
    end
  end
end
