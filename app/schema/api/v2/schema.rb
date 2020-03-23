class Api::V2::Schema < Api::V3::Schema
  class << self
    def all_definitions
      definitions.merge(Api::V2::Models.definitions)
    end
  end
end
