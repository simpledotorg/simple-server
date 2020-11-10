require "factory_bot_rails"
require "faker"

class SeedPatients
  include ActiveSupport::Benchmarkable

  attr_accessor :counts
  attr_reader :logger
  attr_reader :scale_factor

  def initialize(scale_factor: ENV["SEED_FACTOR"]&.to_f || 1.0)
    @counts = {}
    @scale_factor = scale_factor
    @logger = Rails.logger.child(class: self.class.name)
  end

  def self.random_gender
    return Patient::GENDERS.sample if Patient::GENDERS.size == 2
    num = rand(100)
    if num <= 1
      :transgender
    elsif num > 1 && num < 50
      :male
    else
      :female
    end
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
        patient_info = facility.assigned_patients.pluck(:id, :recorded_at)
        create_bps(patient_info, user)
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
    patient
  end

  def create_bps(patient_info, user)
    facility = user.facility
    bp_attrs = patient_info.each_with_object([]) do |(patient_id, recorded_at), arry|
      patient_control_ratio = rand(100)
      blood_pressures_to_create.times do
        bp_time = Faker::Time.between(from: recorded_at, to: 1.day.ago)
        bp_attributes = {
          device_created_at: bp_time,
          device_updated_at: bp_time,
          facility_id: facility.id,
          patient_id: patient_id,
          recorded_at: bp_time,
          user_id: user.id
        }
        control_trait = rand(100) > patient_control_ratio ? :under_control : :hypertensive
        arry << FactoryBot.attributes_for(:blood_pressure, control_trait, bp_attributes)
      end
    end
    result = BloodPressure.import(bp_attrs, returning: [:id, :recorded_at, :patient_id])

    encounters = []
    result.results.each do |row|
      bp_id, recorded_at, patient_id = *row
      encounters << {
        blood_pressure_id: bp_id,
        id: SecureRandom.uuid,
        device_created_at: recorded_at,
        device_updated_at: recorded_at,
        encountered_on: recorded_at,
        facility_id: facility.id,
        patient_id: patient_id,
        timezone_offset: 0
      }
    end
    observations = encounters.each_with_object([]) do |encounter, arry|
      arry << {
        created_at: encounter[:encountered_on],
        encounter_id: encounter[:id],
        observable_id: encounter.delete(:blood_pressure_id),
        observable_type: "BloodPressure",
        updated_at: encounter[:encountered_on],
        user_id: user.id,
      }
    end
    Encounter.import(encounters)
    Observation.import(observations)
    counts[user.facility.slug][:blood_pressure] = result.ids.size
  end
end
