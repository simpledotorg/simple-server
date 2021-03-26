module Experimentation
  class Experiment < ActiveRecord::Base
    has_many :treatment_cohorts

    validates :name, presence: true, uniqueness: true
    validates :state, presence: true
    validates :subject_type, presence: true, inclusion: {in: %w[scheduled_patients stale_patients]}

    enum state: [:active, :inactive], _prefix: true
  end
end
