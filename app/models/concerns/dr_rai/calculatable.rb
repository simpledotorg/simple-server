# Calculatable gets the data for different Dr. Rai Indicators
module DrRai
  module Calculatable

    # This should be implemented by all children of DrRai::Indicator
    def indicator_function
      raise 'Unimplemented'
    end
  end
end
