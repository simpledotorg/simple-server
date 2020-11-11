module Seed
  class Config
    MAX_NUM_OF_FACILITIES_PER_FACILITY_GROUP = 200
    MAX_NUM_OF_USERS_PER_FACILITY = 2

    # There are two seed configs: fast and large
    def initialize
      @type = case SimpleServer.env
      when "development", "test"
        then "fast"
      when "sandbox", "staging"
        then "large"
      else
        raise ArgumentError, "Invalid SimpleServer.env #{SimpleServer.env} for Seed configuration"
      end
      Dotenv.load!(".env.seed.#{type}")
    end

    attr_reader :type

    # This is the overall percentage to scale the dataset size by - a factor of 1.0
    # will product a dataset roughly the size of IHCI
    def scale_factor
      Float(ENV["SCALE_FACTOR"] || 0.1)
    end

    # In test mode, randomness is turned off so that tests can make deterministic assertions on results.
    def test_mode
      Rails.env.test?
    end
    alias_method :test_mode?, :test_mode

    def number_of_facility_groups
      Integer(ENV["NUMBER_OF_FACILITY_GROUPS"])
    end

    def max_number_of_users_per_facility
      Integer(ENV["MAX_NUMBER_OF_USERS_PER_FACILITY"])
    end

    def max_number_of_facilities_per_facility_group
      Integer(ENV["MAX_NUMBER_OF_FACILITIES_PER_FACILITY_GROUP"])
    end

    def max_patients_to_create
      {
        community: Integer(ENV["MAX_PATIENTS_TO_CREATE_COMMUNITY"]),
        small: Integer(ENV["MAX_PATIENTS_TO_CREATE_SMALL"]),
        medium: Integer(ENV["MAX_PATIENTS_TO_CREATE_MEDIUM"]),
        large: Integer(ENV["MAX_PATIENTS_TO_CREATE_LARGE"])
      }
    end

    def max_bps_to_create
      Integer(ENV["MAX_BPS_TO_CREATE"])
    end
  end
end
