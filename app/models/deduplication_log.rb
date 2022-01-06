# frozen_string_literal: true

class DeduplicationLog < ApplicationRecord
  belongs_to :deleted_record, -> { with_discarded }, polymorphic: true, foreign_type: :record_type
  belongs_to :deduped_record, -> { with_discarded }, polymorphic: true, foreign_type: :record_type
  belongs_to :user, optional: true

  def duplicate_records
    # TODO: write this as a relationship if possible
    DeduplicationLog.where(deduped_record: deduped_record).map(&:deleted_record)
  end
end
