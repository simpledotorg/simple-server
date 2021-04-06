module Experimentation
  class TreatmentGroup < ActiveRecord::Base
    belongs_to :experiment
    has_many :reminder_templates, dependent: :delete_all
    has_many :treatment_group_memberships
    has_many :patients, through: :treatment_group_memberships

    validates :index, presence: true, numericality: {greater_than_or_equal_to: 0}
    validates :description, presence: true, uniqueness: { scope: :experiment_id }
    validate :index_order_within_experiment, if: :index_changed?

    private

    def index_order_within_experiment
      indexes = experiment.treatment_groups.pluck(:index)
      indexes << index
      unless indexes.sort == (0..indexes.length - 1).to_a
        errors.add(:index, "treatment group indexes within an experiment must be consecutive starting at zero")
      end
    end
  end
end
