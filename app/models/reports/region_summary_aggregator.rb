module Reports
  class RegionSummaryAggregator
    # After getting the region summary, this class is respobsible for
    # aggregating the data within the region summary. The only dimension along
    # which we aggregate is time i.e. :month_date. Currently, there are only
    # two cardinalities within these dimensions: "monthly, and :quarterly

    def initialize(results_hash)
      @data = results_hash
    end

    # BEGIN Grouping Functions
    #
    # NOTE: For these functions, the result hash must already exist. This means
    # `.call` should have succeeded. Since Ruby is untyped, there is no innate
    # way to enforce this; except to infer on the structure of the hash at runtime.

    def monthly
      raise("Malformed results hash") unless well_formed?
      @data
    end

    def quarterly(with: :sum)
      raise("Malformed results hash") unless well_formed?
      case with
      when :sum
        # Given the data
        # | J | F | M | A | M | J | J | A | S | O | N | D |
        # | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
        # ...this algorithm produces
        # |    Q1     |    Q2     |    Q3     |    Q4     |
        # |     3     |     3     |     3     |     3     |
        @data.map do |facility, months|
          # NOTE: `months` here is a Period[]
          aggregated = {}

          months.each do |period, stats|
            quarter = period.to_quarter_period
            aggregated[quarter] ||= {}
            stats.each do |attr, val|
              if val.is_a? Numeric
                if aggregated[quarter][attr].nil?
                  aggregated[quarter][attr] = val
                else
                  aggregated[quarter][attr] += val
                end
              else
                # This catches the other case where the data is either a Date or a String
                aggregated[quarter][attr] = val
              end
            end
          end
          [facility, aggregated]
        end.to_h

      when :average
        # Given the data
        # | J | F | M | A | M | J | J | A | S | O | N | D |
        # | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
        # ...this algorithm produces
        # |    Q1     |    Q2     |    Q3     |    Q4     |
        # |     1     |     1     |     1     |     1     |
        raise("Unimplemented")
      when :eoq
        # Given the data
        # | J | F | M | A | M | J | J | A | S | O | N | D |
        # | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
        # ...this algorithm produces
        # |    Q1     |    Q2     |    Q3     |    Q4     |
        # |     1     |     1     |     1     |     1     |
        # Note: This is different from average because it takes the data of the
        # last month of the quarter as the value for the quarter
        @data.map do |facility, months|
          aggregated = {}
          months
            .sort_by { |k, v| k }
            .to_h
            .each_slice(3) do |quarter_window|
              selected = quarter_window.last
              month_period, stats = selected
              quarter = month_period.to_quarter_period
              aggregated[quarter] = {}
              stats.each do |attr, val|
                aggregated[quarter][attr] = val
              end
            end
          [facility, aggregated]
        end.to_h
      when :rollup
        # Given the data
        # | J | F | M | A | M | J | J | A | S | O | N | D |
        # | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
        # ...this algorithm produces
        # |    Q1     |    Q2     |    Q3     |    Q4     |
        # |     3     |     6     |     9     |    12     |
        @data.map do |facility, months|
          aggregated = {}
          months.each do |period, stats|
            quarter = period.to_quarter_period
            aggregated[quarter] = if aggregated.has_key?(quarter)
              aggregated[quarter].dup
            elsif aggregated.has_key?(quarter.previous)
              aggregated[quarter.previous].dup
            else
              {}
            end
            stats.each do |attr, val|
              if val.is_a? Numeric
                if aggregated[quarter][attr].nil?
                  aggregated[quarter][attr] = val
                else
                  aggregated[quarter][attr] += val
                end
              else
                # This catches the other case where the data is either a Date or a String
                aggregated[quarter][attr] = val
              end
            end
          end
          [facility, aggregated]
        end.to_h
      else
        raise("Unimplemented")
      end
    end

    def well_formed?
      # This is an effect of an old code base. Ideally, this is type-checking.
      # But since we are building on a righ without type-checking, we have to
      # manually do these checks.
      @data.all? do |facility, period_data|
        facility.is_a?(String) &&
          period_data.all? do |period, _|
            period.is_a? Period
          end
      end
    end

    # END Grouping Functions
  end
end
