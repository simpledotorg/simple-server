class PatientBusinessIdentifier < ApplicationRecord
  include Mergeable

  belongs_to :patient

  enum identifier_type: {
    simple_bp_passport: 'simple_bp_passport'
  }

  validates :identifier, presence: true
  validates :identifier_type, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def shortcode
    case identifier_type
    when "simple_bp_passport"
      identifier.split(/[^\d]/).join[0..6].insert(3, '-')
    else
      identifier
    end
  end
end
