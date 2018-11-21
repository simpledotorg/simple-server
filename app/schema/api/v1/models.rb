class Api::V1::Models < Api::Current::Models
  class << self

    def definitions
      Api::Current::Models.definitions.merge(medical_history: medical_history)
    end
  end
end