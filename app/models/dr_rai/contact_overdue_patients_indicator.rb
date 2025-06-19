module DrRai
  class ContactOverduePatientsIndicator < Indicator
    def indicator_function
      range = Range.new(Period.current.advance(months: -4), Period.current)
      data = Reports::RegionSummary.call(region, range: range)
      quarterlies = Reports::RegionSummary.group_by(grouping: :quarter, data: data)
      quarterlies[region.slug].map do |t, data|
        [t, data['contactable_patients_called']]
      end.to_h
    end
  end
end
