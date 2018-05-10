module MergeRecord
  def self.merge(where_clauses, record)
    existing_record = record.class.find_by(where_clauses)
    if existing_record.nil? || record.updated_at > existing_record.updated_at
      record.save
    end
  end

  def self.bulk_merge_on_id(records)
    records.each do |record|
      merge({id: record.id}, record)
    end
  end
end