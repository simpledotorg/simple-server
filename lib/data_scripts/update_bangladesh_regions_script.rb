class UpdateBangladeshRegionsScript < DataScript
  attr_reader :logger
  attr_reader :results

  def self.call(*args)
    new(*args).call
  end

  def initialize(*args)
    super(*args)
    fields = {module: :data_script, class: self.class}
    @logger = Rails.logger.child(fields)
    @results = {
      dry_run: dry_run?,
      facilities_deleted: 0
    }
  end

  def call
    return unless CountryConfig.current_country?("Bangladesh")
    destroy_empty_facilities
    results
  end

  def destroy_empty_facilities
    sql = <<-SQL
      NOT EXISTS (SELECT 1 FROM patients where patients.registration_facility_id = facilities.id) AND
      NOT EXISTS (SELECT 1 FROM patients where patients.assigned_facility_id = facilities.id)
    SQL
    facilities = Facility.where(facility_size: ["community"]).where(sql)
    facilities.each do |facility|
      if run_safely { facility.destroy }
        results[:facilities_deleted] += 1
      end
    end
  end

  def run_safely
    return true if dry_run?
    yield
  end

end
