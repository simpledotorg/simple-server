require 'date'

class Api::Current::Analytics::Mock::UserAnalyticsController < ApplicationController
  layout false

  def show
    @stats_for_user = {}

    now = Date.today
    previous_sunday = now - now.wday
    4.times do |n|
      @stats_for_user[previous_sunday - n.weeks] = n * 5 + 3
    end

    respond_to do |format|
      format.html { render :show }
      format.json { render json: @stats_for_user }
    end
  end
end
