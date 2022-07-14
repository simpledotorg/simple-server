require "rails_helper"

RSpec.describe MonthlyStateData::Exporter, reporting_spec: true do
  around do |example|
    # This is in the style of ReportingHelpers::freeze_time_for_reporting_specs.
    # Since FacilityAppointmentScheduledDays only keeps the last 6 months of data, the date cannot be a
    # fixed point in time like the spec helper.
    Timecop.freeze("#{Date.today.end_of_month} 23:00 IST") do
      example.run
    end
  end

  let(:organization) { FactoryBot.create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility1) { create(:facility, facility_group: facility_group) }
  let(:facility2) { create(:facility, facility_group: facility_group) }
  let(:district) { facility1.region.district_region }
  let(:state) { facility1.region.state_region }
  let(:period) { Period.month(Date.today) }
  let(:months) { period.downto(5).reverse.map(&:to_s) }

  describe "#report" do
    context "Hypertension" do
      let(:service) {
        described_class.new(exporter: MonthlyStateData::Hypertension.new(
          region: state,
          period: period,
          medications_dispensation_enabled: false
        ))
      }
      let(:headers) { service.exporter.header_row }
      let(:sections) { service.exporter.section_row }
      let(:district_row) { service.exporter.district_row }

      def find_in_csv(csv_data, row_index, column_name)
        headers = csv_data[2]
        column = headers.index(column_name)
        csv_data[row_index][column]
      end

      it "produces valid csv data" do
        result = service.report
        expect {
          CSV.parse(result)
        }.not_to raise_error
      end

      it "includes the section name, headers, district data and state data" do
        result = service.report
        csv = CSV.parse(result)
        expect(csv[0]).to eq(["Monthly district data for #{state.name} #{period.to_date.strftime("%B %Y")}"])
        expect(csv[1]).to eq(sections)
        expect(csv[2]).to eq(headers)
        expect(csv[3][0]).to eq("All districts")
        expect(csv[3][1]).to eq(state.name.to_s)
        expect(csv[4].slice(0, 3)).to eq(%W[1 #{state.name} #{district.name}])
      end
    end

    context "Diabetes" do
      let(:service) {
        described_class.new(exporter: MonthlyStateData::Diabetes.new(
          region: state,
          period: period,
          medications_dispensation_enabled: false
        ))
      }
      let(:headers) { service.exporter.header_row }
      let(:sections) { service.exporter.section_row }

      def find_in_csv(csv_data, row_index, column_name)
        headers = csv_data[2]
        column = headers.index(column_name)
        csv_data[row_index][column]
      end

      it "produces valid csv data" do
        result = service.report
        expect {
          CSV.parse(result)
        }.not_to raise_error
      end

      it "includes the section name, headers, district data and state data" do
        result = service.report
        csv = CSV.parse(result)
        expect(csv[0]).to eq(["Monthly district data for #{state.name} #{period.to_date.strftime("%B %Y")}"])
        expect(csv[1]).to eq(sections)
        expect(csv[2]).to eq(headers)
        expect(csv[3][0]).to eq("All districts")
        expect(csv[3][1]).to eq(state.name.to_s)
        expect(csv[4].slice(0, 3)).to eq(%W[1 #{state.name} #{district.name}])
      end
    end
  end
end
