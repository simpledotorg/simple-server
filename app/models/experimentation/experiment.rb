module Experimentation
  class Experiment < ActiveRecord::Base
    has_many :treatment_cohorts

    validates :name, presence: true, uniqueness: true
    validates :state, presence: true

    enum state: [:active, :inactive], _prefix: true
  end
end
