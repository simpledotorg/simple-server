class DeduplicationLog < ActiveRecord::Base
  belongs_to :deleted_record, polymorphic: true, foreign_type: :record_type
  belongs_to :deduped_record, polymorphic: true, foreign_type: :record_type
  belongs_to :user, optional: true
end
