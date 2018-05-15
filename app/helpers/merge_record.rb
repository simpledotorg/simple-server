module MergeRecord
  def self.merge(where_clauses, record)
    return record if record.invalid?
    existing_record = record.class.find_by(where_clauses)
    if existing_record.nil?
      record.class.create(record.attributes)
      record
    elsif record.updated_at > existing_record.updated_at
      existing_record.update(record.attributes)
      record
    else
      existing_record
    end
  end

  def self.merge_by_id(record)
    merge({ id: record.id }, record)
  end
end
