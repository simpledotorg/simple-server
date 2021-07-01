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

  def initialize(only_overdue:, assigned_facility: nil, next_appointment_facilities: Facility.none, filters: [])
    @only_overdue = only_overdue
    @relation = PatientSummary.where(next_appointment_facility_id: next_appointment_facilities)
    @relation = @relation.where(assigned_facility_id: assigned_facility.id) if assigned_facility
    @filters = filters
  end

  def call
    result = if @only_overdue
      if filters.include?("only_less_than_year_overdue")
        relation.overdue
      else
        relation.all_overdue
      end
    elsif filters.include?("only_less_than_year_overdue")
      relation.last_year_unvisited
    else
      relation.passed_unvisited
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

  attr_reader :filters, :relation
end
