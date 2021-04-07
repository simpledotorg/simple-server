module Experimentation
  class Experiment < ActiveRecord::Base
    has_many :treatment_groups, dependent: :delete_all
    has_many :patients, through: :treatment_groups

    validates :name, presence: true, uniqueness: true
    validates :state, presence: true
    validates :experiment_type, presence: true
    validate :date_range, if: proc { |experiment| experiment.start_date_changed? || experiment.end_date_changed? }
    validate :one_active_experiment_per_type

    enum state: {
      new: "new",
      selecting: "selecting",
      running: "running",
      complete: "complete"
    }, _suffix: true

    enum experiment_type: {
      active_patients: "active_patients",
      stale_patients: "stale_patients"
    }, _prefix: true

    def group_for(uuid)
      hash = Zlib.crc32(uuid) % treatment_groups.length
      treatment_groups.find_by(index: hash)
    end

    private

    def one_active_experiment_per_type
      existing = self.class.where(state: ["running", "selecting"], experiment_type: experiment_type)
      existing = existing.where("id != ?", id) if persisted?
      if existing.any?
        errors.add(:state, "you cannot have multiple active experiments of type #{experiment_type}")
      end
    end

    def date_range
      if start_date.nil? || end_date.nil?
        errors.add(:date_range, "start date and end date must be set together")
        return
      end
      if start_date > end_date
        errors.add(:date_range, "start date must precede end date")
      end
    end
  end
end
