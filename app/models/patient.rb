class Patient < ApplicationRecord
  enum gender: %i[male female transgender].freeze
end
