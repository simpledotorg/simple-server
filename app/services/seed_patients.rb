require "factory_bot_rails"
require "faker"

class SeedPatients
  include ActiveSupport::Benchmarkable

  attr_accessor :counts
  attr_reader :logger
  attr_reader :scale_factor

  def initialize(scale_factor: 1.0)
    @counts = {}
    @scale_factor = scale_factor
    @logger = Rails.logger.child(class: self.class.name)
  end

  SIZES = Facility.facility_sizes
  MAX_BPS_TO_CREATE = 100
  MAX_PATIENTS_TO_CREATE = {
    SIZES[:community] => 200,
    SIZES[:small] => 800,
    SIZES[:medium] => 2000,
    SIZES[:large] => 4000
  }

  def patients_to_create(facility)
    scaled_max_patients = (MAX_PATIENTS_TO_CREATE.fetch(facility.facility_size) * scale_factor).to_int
    Random.new.rand(0..scaled_max_patients)
  end

  def blood_pressures_to_create
    scaled_max_bps = (MAX_BPS_TO_CREATE * scale_factor).to_int
    Random.new.rand(0..scaled_max_bps)
  end

  def call
    user_roles = [ENV["SEED_GENERATED_ACTIVE_USER_ROLE"], ENV["SEED_GENERATED_INACTIVE_USER_ROLE"]]
    User.includes(phone_number_authentications: :facility).where(role: user_roles).each do |user|
      # TODO high performing means more returning for care in last three months
      # low - lots of patients who havent visited in past 3 months + w/i 12 months
      performance_rank = [:low, :medium, :high]
      facility = user.facility
      slug = facility.slug
      counts[slug] = {patient: 0, blood_pressure: 0}
      benchmark("Seeding records for facility #{slug}") do
        # Set a "birth date" for the Facility that patient records will be based from
        # TODO set to 1.day.ago for the most recent possible bday
        facility_birth_date = Faker::Time.between(from: 3.years.ago, to: 1.day.ago)
        patients_to_create(facility).times do |num|
          create_patient(user, oldest_registration: facility_birth_date)
        end
      end
      puts "Seeding complete for facility: #{slug} counts: #{counts[slug]}"
    end
    pp @counts
  end

  # TODO add some backdated BPs before the facility bday
  def create_patient(user, oldest_registration:)
    recorded_at = Faker::Time.between(from: oldest_registration, to: 1.day.ago)
    patient = FactoryBot.create(:patient,
      recorded_at: recorded_at,
      registration_user: user,
      registration_facility: user.facility)
    counts[user.facility.slug][:patient] += 1
    BloodPressure.transaction do
      create_bps(patient, user, blood_pressures_to_create)
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
