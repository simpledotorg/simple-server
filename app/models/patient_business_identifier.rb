class PatientBusinessIdentifier < ApplicationRecord
  include Mergeable

  belongs_to :patient

  enum identifier_type: {
    simple_bp_passport: 'simple_bp_passport',
    bangladesh_national_id: 'bangladesh_national_id'
  }

  validates :identifier, presence: true, unless: -> { identifier_type == 'bangladesh_national_id' }
  validates :identifier, presence: true, allow_blank: true, if: -> { identifier_type == 'bangladesh_national_id' }
  validates :identifier_type, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def shortcode
    if simple_bp_passport?
      identifier.split(/[^\d]/).join[0..6].insert(3, '-')
    else
      identifier
    end
  end
end
