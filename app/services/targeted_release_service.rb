class TargetedReleaseService
  attr_reader :facilities

  def initialize
    @facilities = ENV.fetch('TARGETED_RELEASE_FACILITY_IDS').split(',')
  end
end
