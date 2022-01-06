# frozen_string_literal: true

class PatientSummaryQuery
  FILTERS = {
    "only_less_than_year_overdue" => "<365 days overdue",
    "phone_number" => "Has phone number",
    "no_phone_number" => "No phone number",
    "high_risk" => "High risk only"
  }.freeze

  def self.call(*args)
    new(*args).call
  end

  def self.filters
    FILTERS
  end

  def self.label_for(filter)
    FILTERS.fetch(filter)
  end

  def initialize(assigned_facilities:, only_overdue: true, filters: [])
    @patient_summaries = PatientSummary.where(assigned_facility_id: assigned_facilities.map(&:id))
    @only_overdue = only_overdue
    @filters = filters
  end

  def call
    result = if only_overdue
      if filters.include?("only_less_than_year_overdue")
        patient_summaries.overdue
      else
        patient_summaries.all_overdue
      end
    elsif filters.include?("only_less_than_year_overdue")
      patient_summaries.last_year_unvisited
    else
      patient_summaries.passed_unvisited
    end

    if filters.include?("high_risk")
      result = result.where("risk_level = 1")
    end
    if filters.include?("phone_number") && filters.include?("no_phone_number")
      return result
    end
    if filters.include?("phone_number")
      result = result.where("latest_phone_number is not null")
    end
    if filters.include?("no_phone_number")
      result = result.where("latest_phone_number is null")
    end
    result
  end

  private

  attr_reader :patient_summaries, :only_overdue, :filters
end
