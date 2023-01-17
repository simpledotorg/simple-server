class QuestionnaireResponse < ApplicationRecord
  include Mergeable

  belongs_to :questionnaire
  belongs_to :facility
  belongs_to :user, optional: true

  scope :for_sync, -> { with_discarded }

  validates :questionnaire_id, presence: true
  validates :facility_id, presence: true
  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  class << self
    def merge(attributes)
      new_record = new(attributes)

      QuestionnaireResponse.transaction do
        existing_record = with_discarded.lock.find_by(id: attributes["id"])
        case merge_status(new_record, existing_record)
          when :discarded
            discarded_record(existing_record)
          when :invalid
            invalid_record(new_record)
          when :new
            create_new_record(attributes)
          when :updated, :identical
            new_content = existing_record.content.merge(new_record.content)
            update_existing_record(existing_record, attributes.merge("content" => new_content))
          when :old
            new_content = new_record.content.merge(existing_record.content)
            update_existing_record(existing_record, {"content" => new_content})
        end
      end
    end
  end
end
