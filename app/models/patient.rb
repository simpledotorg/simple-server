class Patient < ApplicationRecord
  include Mergeable

  GENDERS  = %w[male female transgender].freeze
  STATUSES = %w[active dead migrated unresponsive inactive].freeze

  belongs_to :address, optional: true
  has_many :phone_numbers, class_name: 'PatientPhoneNumber'

  validates_associated :address, if: :address
  validates_associated :phone_numbers, if: :phone_numbers

  def nested_hash(options = {})
    as_json(options.merge(
      except:  %i[address_id  updated_on_server_at],
      include: { address:       { except: :updated_on_server_at },
                 phone_numbers: { except: :updated_on_server_at } }))
  end
end
