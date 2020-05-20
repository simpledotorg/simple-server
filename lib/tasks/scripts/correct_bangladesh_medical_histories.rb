# frozen_string_literal: true

class CorrectBangladeshMedicalHistories
  def self.call(*args)
    new(*args).call
  end

  attr_reader :dryrun, :verbose

  def initialize(dryrun: false, verbose: true)
    @dryrun = dryrun
    @verbose = verbose
  end

  def call
    print_summary

    return if dryrun

    log 'Updating medical histories...'
    update_medical_histories

    log 'Complete. Goodbye.'
  end

  def print_summary
    log "Medical histories with 'unknown' hypertension: #{eligible_medical_histories.count} records"
  end

  def eligible_medical_histories
    MedicalHistory.where(hypertension: 'unknown')
  end

  def update_medical_histories
    eligible_medical_histories.update_all(
      hypertension: 'yes',
      diagnosed_with_hypertension: 'yes'
    )
  end

  def log(message)
    puts message if verbose
  end
end
