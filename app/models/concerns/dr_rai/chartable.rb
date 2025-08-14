# Contains methods required to transform data from their normal form to chartable data
module DrRai
  module Chartable
    extend ActiveSupport::Concern

    class_methods do
      def chartable_internal_keys *keys
        @chartable_internal_keys = keys.map(&:to_sym)
      end

      def chartable_period_key key
        @chartable_period_key = key.to_sym
      end

      def chartable_outer_grouping key
        @chartable_outer_grouping = key.to_sym
      end

      def chartable
        result = {}
        all.each do |record|
          period_key = @chartable_period_key
          the_period = Period.quarter(record.send(period_key))

          internal_keys = @chartable_internal_keys
          internal_data = internal_keys.map { |k| [k, record.send(k)] }.to_h

          outer_grouping = record.send @chartable_outer_grouping
          if result.has_key? outer_grouping
            if result[outer_grouping].has_key?(the_period)
              internal_keys.each do |k|
                result[outer_grouping][the_period][k] += record.send(k)
              end
            else
              result[outer_grouping][the_period] = internal_data
            end
          else
            result[outer_grouping] = {
              the_period => internal_data
            }
          end
        end
        result
      end
    end
  end
end
