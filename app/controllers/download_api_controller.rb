class DownloadApiController < ApplicationController
  before_action :authenticate
  attr_reader :client

  def current_facility
    @current_facility ||= client.facility
  end

  def current_facility_group
    @current_facility_group ||= current_facility.facility_group
  end

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      @client = DownloadApiToken.find_by(access_token: token, enabled: true)

      @client.present?
    end
  end
end