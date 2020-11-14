module Seed
  class FakeNames
    include Singleton
    def initialize
      @csv = CSV.read(Rails.root.join("db/fake_names.csv").to_s, headers: true).by_col!
      @village_names = @csv["Villages/Cities"].compact
      @male_first_names = @csv["Male First Names"].compact
      @female_first_names = @csv["Female First Names"].compact
    end

    def _csv
      @csv
    end

    def village_name
      @village_names.sample
    end
  end
end