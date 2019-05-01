class TargetedReleaseService
  attr_reader :eligible_facilities

  def initialize
    @eligible_facilities = ENV.fetch('TARGETED_RELEASE_FACILITY_IDS').split(',')
  end

  def facility_eligible?(facility_id)
    return true if @eligible_facilities.blank?
    @eligible_facilities.include?(facility_id)
  end
end
