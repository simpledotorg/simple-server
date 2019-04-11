class Api::V2::Schema < Api::Current::Schema
  class << self
    def all_definitions
      definitions.merge(Api::V2::Models.definitions)
    end
  end
end
