require "factory_bot_rails"
require "faker"

class SeedPatients
  include ActiveSupport::Benchmarkable

  attr_reader :bps_to_create
  attr_accessor :counts
  attr_reader :logger
  attr_reader :patients_to_create

  def initialize(patients_to_create: (25..50), bps_to_create: (0..25))
    @counts = {}
    @bps_to_create = Array(bps_to_create)
    @patients_to_create = Array(patients_to_create)
    @logger = Rails.logger.child(class: self.class.name)
  end

  def call
    user_roles = [ENV["SEED_GENERATED_ACTIVE_USER_ROLE"], ENV["SEED_GENERATED_INACTIVE_USER_ROLE"]]
    User.includes(phone_number_authentications: :facility).where(role: user_roles).each do |user|
      facility = user.facility
      slug = facility.slug
      counts[slug] = {patient: 0, blood_pressure: 0}
      benchmark("Seeding records for facility #{slug}") do
        # Set a "birth date" for the Facility that patient records will be based from
        facility_birth_date = Faker::Time.between(from: 3.years.ago, to: 3.months.ago)
        patients_to_create.sample.times do |num|
          create_patient(user, oldest_registration: facility_birth_date)
        end
      end
      puts "Seeding complete for facility: #{slug} counts: #{counts[slug]}"
    end
    pp @counts
  end

  def create_patient(user, oldest_registration:)
    recorded_at = Faker::Time.between(from: oldest_registration, to: 1.months.ago)
    patient = FactoryBot.create(:patient,
      recorded_at: recorded_at,
      registration_user: user,
      registration_facility: user.facility)
    counts[user.facility.slug][:patient] += 1
    BloodPressure.transaction do
      create_bps(patient, user, bps_to_create.sample)
    end
  end

  def create_bps(patient, user, number)
    patient_control_ratio = rand(100)
    number.times do
      bp_time = Faker::Time.between(from: patient.recorded_at, to: 1.day.ago)
      bp_attributes = {
        device_created_at: bp_time,
        device_updated_at: bp_time,
        facility: user.facility,
        patient: patient,
        recorded_at: bp_time,
        user: user
      }
      control_trait = if rand(100) > patient_control_ratio
        :under_control
      else
        :hypertensive
      end
      patient.blood_pressures << FactoryBot.build(
        :blood_pressure,
        control_trait,
        bp_attributes
      )
      counts[user.facility.slug][:blood_pressure] += 1
    end
  end
end
