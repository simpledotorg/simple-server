# frozen_string_literal: true

class ResourcesController < AdminController
  skip_after_action :verify_authorized, :verify_access_authorized, only: [:index]
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
  end
end
