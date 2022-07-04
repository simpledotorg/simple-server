class Dashboard::Diabetes::DownloadsDropdownComponent < ApplicationComponent
  include QuarterHelper

  attr_reader :region, :current_admin

  def initialize(region:, current_admin:)
    @region = region
    @current_admin = current_admin
  end
end
