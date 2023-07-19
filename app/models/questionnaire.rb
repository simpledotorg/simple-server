class Questionnaire < ApplicationRecord
  has_many :questionnaire_responses

  enum questionnaire_type: {
    monthly_screening_reports: "monthly_screening_reports",
    monthly_supplies_reports: "monthly_supplies_reports",
    drug_stock_reports: "drug_stock_reports"
  }

  validates :dsl_version, uniqueness: {
    scope: [:questionnaire_type, :is_active],
    message: "has already been taken for given questionnaire_type",
    conditions: -> { active }
  }
  validate :dsl_version_semver
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

  def dsl_version_semver
    unless /^[0-9]+.[0-9]+$/ === dsl_version || /^[0-9]+$/ === dsl_version
      errors.add(:dsl_version, "should be a Semver of pattern X.Y where X & Y are integers")
    end
  end

  def validate_layout
    JSON::Validator.fully_validate(layout_schema, layout).each do |error_string|
      errors.add(:layout_schema, error_string.split("in schema").first)
    end
  end

  def transform_layout(&blk)
    self.layout = apply_recursively_to_layout(layout, &blk)
  end

  private

  def layout_schema
    layout_definitions = {
      "1" => Api::V4::Models::Questionnaires::DSLVersion1,
      "1.1" => Api::V4::Models::Questionnaires::DSLVersion1Dot1,
      "1.2" => Api::V4::Models::Questionnaires::DSLVersion1Dot2
    }
    layout_definitions.fetch(dsl_version).view_group.merge(definitions: Api::V4::Schema.all_definitions)
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
