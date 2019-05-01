class TargetedReleaseService
  def initialize
    @facilities = ENV.fetch('TARGETED_RELEASE_FACILITY_IDS').split(',')
  end

  def facility_eligible?(facility_id)
    @facilities.include?(facility_id)
  end
end
