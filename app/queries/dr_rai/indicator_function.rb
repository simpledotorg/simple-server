# Base Query for a DrRai indicator
#
# This is our harness to force the queries created in Metabase to follow the
# format of the data in the Simple Dashboard. Thus, all queries we would want
# to use with the Dr Rai component should include this module.
module DrRai
  module IndicatorFunction
    def valid?
      raise "The result of the query must be present beforehand." if @result.nil?

      raise "Invalid structure" unless valid_structure?
    end

    # This method is what the indicator uses to verify that it gets what should
    # come back from the DB. Ideally, it would be validating a 2D array for the
    # columns. If indicators want to get ambitious, they can validate the
    # column types. But this is not necessary.
    def valid_structure?
      raise "Unimplemented"
    end

    # This is the method all Dr. Rai indicator functions should implement to
    # transform their resultant query to the dashboard format
    def transform!
      raise "Unimplemented"
    end
  end
end
