module Reports::Percentage
  def percentage(numerator, denominator, with_rounding: true)
    return 0 if numerator.nil? || denominator.nil? || denominator == 0 || numerator == 0
    if with_rounding
      ((numerator.to_f / denominator) * 100).round(Reports::PERCENTAGE_PRECISION)
    else
      ((numerator.to_f / denominator) * 100)
    end
  end

  def rounded_percentages(counts_hash)
    total = counts_hash.values.sum
    return counts_hash if total.zero?

    percentages = counts_hash.transform_values { |count| percentage(count, total, with_rounding: false) }
    number_of_1s_to_distribute = 100 - percentages.values.map(&:floor).sum

    percentages
      .sort_by { |_, percentage| fractional_part(percentage) }.reverse.to_h
      .transform_values do |value|
      if number_of_1s_to_distribute > 0
        number_of_1s_to_distribute -= 1
        value.floor + 1
      else
        value.floor
      end
    end
  end

  private

  def fractional_part(number)
    number - number.floor
  end
end
