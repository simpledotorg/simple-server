# frozen_string_literal: true

class SettingsController < AdminController
  skip_after_action :verify_authorization_attempted, only: [:index]

  def index
  end
end
