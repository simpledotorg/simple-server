# frozen_string_literal: true

class Admin::ErrorTracesController < AdminController
  before_action :require_power_user

  class Boom < StandardError
  end

  def index
  end

  def create
    if error_params.dig(:type) == "job"
      raise_error = true
      TracerJob.perform_async(Time.current.iso8601, raise_error)
      redirect_to admin_error_traces_path, notice: "Background job error tracer submitted"
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
