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
    enum experiment_type: {
      current_patient_reminder: "current_patient_reminder",
      stale_patient_reminder: "stale_patient_reminder"
    }, _prefix: true

    def group_for(uuid)
      hash = Zlib.crc32(uuid) % treatment_groups.length
      treatment_groups.find_by(index: hash)
    end
  end
end
