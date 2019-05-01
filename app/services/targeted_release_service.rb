class TargetedReleaseService
  attr_reader :eligible_facilities

  def initialize
    @eligible_facilities = ENV.fetch('TARGETED_RELEASE_FACILITY_IDS').split(',')
  end
end
