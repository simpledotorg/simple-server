module DrRai
  class ContactOverduePatientsIndicator < Indicator
    def display_name
      "Contact overdue patients"
    end

    def indicator_function
      range = Range.new(Period.current.advance(months: -4), Period.current)
      data = Reports::RegionSummary.call(region, range: range)
      quarterlies = Reports::RegionSummary.group_by(grouping: :quarter, data: data)
      quarterlies[region.slug].map do |t, data|
        [t, data['contactable_patients_called']]
      end.to_h
    end

    def target_type
      "DrRai::PercentageTarget"
    end

    def target_type_frontend
      "percent"
    end
  end
end
