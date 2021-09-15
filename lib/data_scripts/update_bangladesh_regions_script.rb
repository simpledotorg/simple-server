class UpdateBangladeshRegionsScript < DataScript
  attr_reader :logger

  def self.call(*args)
    new(*args).call
  end

  def initialize(*args)
    super(*args)
    fields = {module: :data_script, class: self.class}
    @logger = Rails.logger.child(fields)
  end

  def call
    return unless CountryConfig.current_country?("Bangladesh")
    destroy_empty_facilities


  end

  def destroy_empty_facilities
    sql = <<-SQL
      NOT EXISTS (SELECT 1 FROM patients where patients.registration_facility_id = facilities.id) AND
      NOT EXISTS (SELECT 1 FROM patients where patients.assigned_facility_id = facilities.id)
    SQL
    facilities = Facility.where(facility_size: ["community", "small"]).where(sql)
    facilities.each do |facility|
      facility.destroy unless dry_run?
    end
  end
end
