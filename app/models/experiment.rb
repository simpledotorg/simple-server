class Experiment < ActiveYaml::Base
  set_root_path "config/data"
  set_filename "experiments"
  field :id
  field :active
  field :variations

  has_many :appointment_reminders
end