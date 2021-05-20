module Experimentation
  class ReminderTemplate < ActiveRecord::Base
    belongs_to :treatment_group
    has_many :notifications

    validates :message, presence: true
    validates :remind_on_in_days, presence: true, numericality: {only_integer: true}
  end
end
