class Api::V1::Schema < Api::Current::Schema

  class << self
    def all_definitions
      Api::Current::Schema.definitions.merge(Api::V1::Models.definitions)
    end
  end
end
