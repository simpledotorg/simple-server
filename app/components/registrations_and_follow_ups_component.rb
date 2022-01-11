class RegistrationsAndFollowUpsComponent < ViewComponent::Base
  include Reports::RegionsUrlHelper
  attr_reader :region
  attr_reader :repository
  attr_reader :current_admin
  attr_reader :current_period
  attr_reader :range

  def initialize(region, current_admin:, repository:, current_period:)
    @region = region
    @repository = repository
    @range = repository.periods
    @current_admin = current_admin
    @current_period = current_period
  end

  def follow_ups_definition
    if current_admin.feature_enabled?(:follow_ups_v2)
      :follow_up_patients_copy_v2
    else
      :follow_up_patients_copy
    end
  end

  def number_or_dash_with_delimiter(value, options = {})
    return "-" if value.blank? || value.zero?
    number_with_delimiter(value, options)
  end
end
