# frozen_string_literal: true

class CleanAncientDates
  DATE_CUTOFF = Date.new(2000, 1, 1)

  def self.call(*args)
    new(*args).call
  end

  attr_reader :verbose, :dryrun

  def initialize(verbose: true, dryrun: false)
    @verbose = verbose
    @dryrun = dryrun
  end

  def call
    log "#{eligible_patients.count} ancient patient records to be cleaned."

    return if dryrun

    eligible_patients.includes(:blood_pressures, :blood_sugars).each do |patient|
      clean_blood_pressures_for(patient)
      clean_blood_sugars_for(patient)
      update_registration_for(patient)
    end
  end

  private

  def clean_blood_pressures_for(patient)
    ancient_blood_pressures = patient.blood_pressures.where("recorded_at < ?", DATE_CUTOFF)

    ancient_blood_pressures.each(&:discard!)
  end

  def clean_blood_sugars_for(patient)
    ancient_blood_sugars = patient.blood_sugars.where("recorded_at < ?", DATE_CUTOFF)

    ancient_blood_sugars.each(&:discard!)
  end

  def update_registration_for(patient)
    patient.update!(recorded_at: registration_date_for(patient))
  end

  def registration_date_for(patient)
    [
      *patient.reload.blood_pressures.map(&:recorded_at),
      *patient.reload.blood_sugars.map(&:recorded_at),
      patient.device_created_at
    ].min
  end

  def eligible_patients
    @eligible_patients ||= Patient.where("recorded_at < ?", DATE_CUTOFF)
  end

  def log(message)
    puts message if verbose
  end
end
