class HealthController < ApplicationController
  def ping
    render plain: "OK", status: :ok
  end
end
