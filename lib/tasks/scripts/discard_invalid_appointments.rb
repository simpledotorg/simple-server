# frozen_string_literal: true

class DiscardInvalidAppointments
  def initialize(patient:, dry_run: true)
    @patient = patient
    @dry_run = dry_run
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    if last_valid_appointment.nil?
      # dry_run will skip patients who don't have at least 1 scheduled appointment within a month
      return if @dry_run

      @patient.latest_scheduled_appointment.update!(scheduled_date: Date.today + 31.days)
    end

    invalid_appointment_ids = @patient
      .appointments
      .where(status: "scheduled")
      .pluck(:id) - [last_valid_appointment&.id]

    invalid_appointments = Appointment
      .where(id: invalid_appointment_ids)
      .order(scheduled_date: :asc)

    Rails.logger.info msg: <<-INFO
    For patient: #{@patient.id}, discarding #{invalid_appointments.count} appointment(s) 
    scheduled between #{invalid_appointments&.first&.scheduled_date} and #{invalid_appointments&.last&.scheduled_date}
    Preserving appointment scheduled at #{last_valid_appointment&.scheduled_date}
    INFO

    unless @dry_run
      Appointment.where("id in (?)", invalid_appointment_ids).discard_all
    end
  end

  def last_valid_appointment
    @patient
      .latest_scheduled_appointments
      .where("scheduled_date <= ?", Date.today + 31.days)
      .first
  end
end
