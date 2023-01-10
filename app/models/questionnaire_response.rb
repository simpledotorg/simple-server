class QuestionnaireResponse < ApplicationRecord
  belongs_to :questionnaire
  belongs_to :facility
  belongs_to :user

  scope :for_sync, -> { with_discarded }

  # let existing record be A, new record be B
  # if same keys
  #   if record B is newer, keep record B's keys
  #   if record B is older, keep record A's keys
  # if different keys
  #   if record B is newer, add record B's keys
  #   if record B is older, add record B's keys
  #
  # other cases:
  # let there be no existing record, only new record A
  def merge_with_content(transformed_params)
    new_record = QuestionnaireResponse.new(transformed_params)
    existing_record = QuestionnaireResponse.with_discarded.find_by(id: transformed_params["id"])
    existing_content = existing_record&.content
    merge(transformed_params)

    if existing_content
      existing_record.reload
      new_content = if new_record.device_created_at > existing_record.device_created_at
        existing_content.merge(new_record.content)
      else
        new_record.content.except(existing_content.keys)
      end

      existing_record.update(content: new_content)
    end
  end
end
