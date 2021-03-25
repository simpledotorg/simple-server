module Experimentation
  class Experiment < ActiveRecord::Base
    has_many :treatment_cohorts

    validates :state, presence: true

    enum state: [:active, :inactive], _prefix: true
  end
end
