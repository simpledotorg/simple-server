class Questionnaire < ApplicationRecord
  SUPPORTED_LAYOUT_DSL_VERSIONS = [1]

  has_many :questionnaire_responses

  enum questionnaire_type: {
    monthly_screening_reports: "monthly_screening_reports"
  }

  validates :dsl_version, presence: true
  validates :dsl_version, uniqueness: {
    scope: [:questionnaire_type, :is_active],
    message: "has already been taken for given questionnaire_type",
    conditions: -> { active }
  }
  validate :validate_layout

  scope :active, -> { where(is_active: true) }
  scope :for_sync, -> { with_discarded.active }

  before_validation :generate_ids_for_layout

  def localized_layout
    transform_layout { |l| localize_layout(l) }
  end

  def generate_ids_for_layout
    transform_layout { |l| generate_layout_id(l) }
  end

  def layout_valid?
    JSON::Validator.validate(layout_schema, layout)
  end

  def validate_layout
    unless layout.is_a?(Hash)
      return errors.add(:layout, "should be valid JSON")
    end

    JSON::Validator.fully_validate(layout_schema, layout).each do |error_string|
      errors.add(:layout, error_string.split("in schema").first)
    end
  end

  def transform_layout(&blk)
    return layout unless layout.is_a?(Hash)

    self.layout = apply_recursively_to_layout(layout, &blk)
  end

  def self.default_layout
    {
      type: "group",
      view_type: "view_group",
      display_properties: {
        orientation: "vertical"
      },
      item: []
    }
  end

  private

  def layout_schema
    # TODO: When dsl_version is incremented, insert a switch here.
    Api::V4::Models::Questionnaires::Version1.group.merge(
      definitions: Api::V4::Schema.all_definitions
    )
  end

  def apply_recursively_to_layout(sub_layout, &blk)
    new_sub_layout = blk.call(sub_layout)

    items = new_sub_layout["item"]
    return new_sub_layout unless items

    new_sub_layout.merge({"item" => items.map { |item| apply_recursively_to_layout(item, &blk) }})
  end

  def localize_layout(sub_layout)
    text = sub_layout["text"]
    return sub_layout unless text

    sub_layout.merge({"text" => I18n.t!(text)})
  end

  def generate_layout_id(sub_layout)
    return sub_layout if sub_layout["id"]
    sub_layout.merge({"id" => SecureRandom.uuid})
  end
end
