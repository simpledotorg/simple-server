# frozen_string_literal: true

class CorrectBangladeshMedicationDosages
  PROTOCOL_DOSAGES = {
    'Amlodipine' => '5 mg',
    'Losartan Potassium' => '50 mg',
    'Hydrochlorothiazide' => '12.5 mg'
  }.freeze

  def self.call(*args)
    new(*args).call
  end

  attr_reader :dryrun

  def initialize(dryrun: false)
    @dryrun = dryrun
  end

  def call
    print_summary

    return if dryrun

    update_dosages
  end

  def print_summary
    puts 'Zero dosage medications found:'
    PROTOCOL_DOSAGES.keys.each { |drug| puts "#{drug}: #{eligible_drugs(drug).count} records" }
  end

  def update_dosages
    PROTOCOL_DOSAGES.keys.each do |drug|
      eligible_drugs(drug).update_all(dosage: PROTOCOL_DOSAGES[drug])
    end
  end

  def eligible_drugs(name)
    PrescriptionDrug.where(name: name, dosage: '0 mg')
  end
end
