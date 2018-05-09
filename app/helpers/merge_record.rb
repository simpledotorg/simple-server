module MergeRecord

  # make this an ActiveSupport::Concern ?

  def self.merge(model, where_clauses, record)
    existing_record = model.find_by(where_clauses)
    if existing_record.nil?
      model.create(where_clauses.merge(record))
    else
      if record[:updated_at] > existing_record.updated_at
        existing_record.update(record)
      end
      existing_record
    end
  end

  def self.bulk_merge_on_id(model, records)
    records.each do |record|
      merge(model, {id: record[:id]}, record)
    end
  end
end