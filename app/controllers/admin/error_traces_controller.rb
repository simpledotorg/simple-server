class Admin::ErrorTracesController < AdminController
  before_action :require_power_user

  class Boom < StandardError
  end

  def index
    authorize { "ok" }
  end

  def create
    authorize { "ok" }
    if error_params.dig(:type) == "job"
      raise_error = true
      TracerJob.perform_async(Time.current.iso8601, raise_error)
    else
      raise Boom, "Error test created by #{current_admin.full_name}"
    end
  end

  private

  def require_power_user
    authorize { current_admin.power_user? }
  end

  def error_params
    params.permit(:type)
  end
end
