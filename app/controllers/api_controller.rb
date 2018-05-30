class APIController < ApplicationController
  TIME_WITHOUT_TIMEZONE_FORMAT = '%FT%T.%3NZ'.freeze

  skip_before_action :verify_authenticity_token

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end
end
