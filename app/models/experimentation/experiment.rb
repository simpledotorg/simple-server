module Experimentation
  class Experiment < ActiveRecord::Base
    has_many :treatment_groups
    has_many :patients, through: :treatment_groups

    validates :name, presence: true, uniqueness: true
    validates :state, presence: true
    validates :experiment_type, presence: true

    enum state: {
      new: "new",
      selecting: "selecting",
      live: "live",
      complete: "complete"
    }, _prefix: true

    def fetch_message(appointment, communication_type, locale, date: Date.today)
    #  traverse the experiment's data and fetch the appropriate message to queue
    end

    def queueable_message_exists?(appointment, date: Date.today)
      # returns a boolean which determines whether or not to further process this appointment
      # true: if this appointment has a message for date passed in
      # false: if there isn't a message for this day (or) the patient already visited
    end
  end
end
