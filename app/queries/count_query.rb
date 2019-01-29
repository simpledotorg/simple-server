class CountQuery
  attr_reader :relation
  def initialize(relation)
    @relation = relation
  end

  def distinct_count(column_name, group_by_columns: nil, group_by_period: nil)
    group_relation_by_columns(group_by_columns) if group_by_columns.present?
    group_relation_by_period(group_by_period) if group_by_period.present?

    relation.count("distinct #{column_name}")
  end

  private

  def group_relation_by_columns(columns)
    @relation = relation.group(*columns)
  end

  def group_relation_by_period(period:, column:, options: {})
    @relation = relation.group_by_period(period, column, options)
  end
end