# frozen_string_literal: true

class CorrectBangladeshMedicationDosages
  def self.call(*args)
    new(*args).call
  end

  attr_reader :dryrun

  def initialize(dryrun: false)
    @dryrun = dryrun
  end

  def call
    puts "Thanks for playing #{dryrun}"
  end
end
