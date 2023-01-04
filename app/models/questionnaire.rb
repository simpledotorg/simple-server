class Questionnaire < ApplicationRecord

  enum questionnaire_type: {
    monthly_screening_reports: "monthly_screening_reports"
  }

  validates :dsl_version, uniqueness: {
    scope: [:questionnaire_type, :is_active],
    message: "has already been taken for given questionnaire_type",
    conditions: -> { active }
  }
  validate :validate_layout

  scope :active, -> { where(is_active: true) }
  scope :for_sync, -> { with_discarded.active }

  def localized_layout
    localize_layout(layout)
  end

  def layout_valid?
    JSON::Validator.validate(layout_schema, layout)
  end

  def validate_layout
    JSON::Validator.fully_validate(layout_schema, layout).each do |error_string|
      errors.add(:layout_schema, error_string.split("in schema").first)
    end
  end

  private

  def layout_schema
    # TODO: When dsl_version is incremented, insert a switch here.
    Api::V4::Models::Questionnaires::Version1.layout.merge(
      definitions: Api::V4::Schema.all_definitions
    )
  end

  def localize_layout(sub_layout)
    sub_layout
      .then { |l| localize_text(l) }
      .then { |l| localize_items_recursively(l) }
  end

  def localize_text(sub_layout)
    text = sub_layout["text"]
    return sub_layout unless text

    sub_layout.merge({"text" => I18n.t!(text)})
  end

  def localize_items_recursively(sub_layout)
    items = sub_layout["item"]
    return sub_layout unless items

    sub_layout.merge({"item" => items.map { |item| localize_layout(item) }})
  end
end
