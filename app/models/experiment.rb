class Experiment < ActiveYaml::Base
  set_root_path "config/data"
  set_filename "experiments"
  field :id
  field :active
  field :variations

  def bucket_size
    variations.keys.count
  end
end