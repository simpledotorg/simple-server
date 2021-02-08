class PatientBreakdownService
  def initialize(region:, period:, with_exclusions: false)
    @region = region
    @facilities = region.facilities
    @period = period
    @with_exclusions = with_exclusions
  end

  attr_reader :period
  attr_reader :facilities
  attr_reader :with_exclusions

  def self.call(*args)
    new(*args).call
  end

  def call
    patients =
      Patient
        .with_hypertension
        .for_reports(with_exclusions: @with_exclusions)
        .where(assigned_facility: @facilities)

    {
      dead: patients.status_dead.count,
      ltfu_patients: patients.ltfu_as_of(period.to_date).count,
      not_ltfu_patients: patients.not_ltfu_as_of(period.to_date).count,
      ltfu_transferred_patients: patients.ltfu_as_of(period.to_date).status_migrated.count,
      not_ltfu_transferred_patients: patients.not_ltfu_as_of(period.to_date).status_migrated.count,
      total_patients: patients.count
    }
  end
end
