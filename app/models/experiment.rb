class Experiment < ActiveRecord::Base
  has_many :experiment_communications #maybe rename to communication_templates or something?
  has_many :appointment_reminders

  def bucket_keys
    @bucket_keys ||= experiment_communications.pluck(:bucket_identifier).uniq.sort
  end

  def bucket_size
    @bucket_size ||= bucket_keys.count
  end

  def bucket_for_patient(patient_id)
    bucket_hash = Zlib.crc32(patient_id) % bucket_size
    key = bucket_keys[bucket_hash]
    variations[key]
  end
end