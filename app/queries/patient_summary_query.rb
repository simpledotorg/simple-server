class PatientSummaryQuery
  def self.call(*args)
    new(*args).call
  end

  # Create the query object with optional base relation and search filters
  #
  # relation: A base AR Relation to scope things off of - this would typically be used for authorization
  # filters: An Array of search filters
  def initialize(relation: PatientSummary.all, filters: [])
    @relation = relation
    @filters = filters
  end

  def call
    result = if filters.include?("only_less_than_year_overdue")
      relation.overdue
    else
      relation.all_overdue
    end
    if filters.include?("phone_number")
      result = result.where("latest_phone_number is not null")
    end
    if filters.include?("no_phone_number")
      result = result.where("latest_phone_number is null")
    end
    if filters.include?("high_risk")
      result = result.where("risk_level = 1")
    end
    result
  end

  private

  attr_reader :filters, :relation
end
