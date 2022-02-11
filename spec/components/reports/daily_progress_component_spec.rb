require "rails_helper"

RSpec.describe Reports::DailyProgressComponent, type: :component do
  it "renders successfully" do
    facility = create(:facility)
    service = Reports::FacilityProgressService.new(facility, Period.current)

    component = described_class.new(service)
    current_date = component.display_date(Date.current)
    expect(render_inline(component).to_html).to include(current_date)
  end

  context "last_30_days" do
    it "returns last 30 days from current date" do
      fake_service = instance_double("Reports::FacilityProgressService")
      Timecop.freeze do
        today = Date.current
        start = today - 29
        component = described_class.new(fake_service)
        expect(component.last_30_days.size).to eq(30)
        expect(component.last_30_days.first).to eq(today)
        expect(component.last_30_days.last).to eq(start)
      end
    end
  end
end
