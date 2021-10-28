module Experimentation
  class ReminderTemplate < ActiveRecord::Base
    belongs_to :treatment_group
    has_many :notifications

    validates :message, presence: true
    validates :remind_on_in_days, presence: true, numericality: {only_integer: true}

    validate :unique_message_per_group

    def unique_message_per_group
      if self.class.find_by(message: message, treatment_group: treatment_group)
        errors.add(:message, "already exists in this treatment group")
      end
    end
  end
end
