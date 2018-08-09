class AdminController < ApplicationController
  before_action :authenticate_admin!
  after_action :verify_authorized
end
