class AdminController < ApplicationController
  before_action :authenticate_admin!
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index
end
