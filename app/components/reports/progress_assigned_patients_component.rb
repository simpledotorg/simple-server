# frozen_string_literal: true

class Reports::ProgressAssignedPatientsComponent < ViewComponent::Base
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :assigned_patients, :region

  def initialize(assigned_patients:, region:)
    @assigned_patients = assigned_patients
    @region = region
  end
end
