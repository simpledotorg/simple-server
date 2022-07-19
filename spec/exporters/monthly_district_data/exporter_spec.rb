require "rails_helper"

RSpec.describe MonthlyDistrictData::Exporter, reporting_spec: true do
  around do |example|
    # This is in the style of ReportingHelpers::freeze_time_for_reporting_specs.
    # Since FacilityAppointmentScheduledDays only keeps the last 6 months of data, the date cannot be a
    # fixed point in time like the spec helper.
    Timecop.freeze("#{Date.today.end_of_month} 23:00 IST") do
      example.run
    end
  end

  describe "#report" do
    before do
      @organization = FactoryBot.create(:organization)
      @facility_group = create(:facility_group, organization: @organization)
      @facility1 = create(:facility, name: "Facility 1", block: "Block 1 - alphabetically first", facility_group: @facility_group, facility_size: :community)
      @facility2 = create(:facility, name: "Facility 2", block: "Block 2 - alphabetically second", facility_group: @facility_group, facility_size: :community)
      @region = @facility1.region.district_region
      @period = Period.month(Date.today)
    end
    context "Hypertension" do
      let(:service) {
        described_class.new(exporter: MonthlyDistrictData::Hypertension.new(
          region: @region,
          period: @period,
          medications_dispensation_enabled: false
        ))
      }
      let(:headers) { service.exporter.header_row }
      let(:sections) { service.exporter.section_row }
      let(:district_row) { service.exporter.district_row }
      let(:facility_size_rows) { service.exporter.facility_size_rows }
      let(:facility_rows) { service.exporter.facility_rows }

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

      it "includes the section name, headers, district data and facility data" do
        result = service.report
        csv = CSV.parse(result)
        expect(csv[0]).to eq(["Monthly facility data for #{@region.name} #{@period.to_date.strftime("%B %Y")}"])
        expect(csv[1]).to eq(sections)
        expect(csv[2]).to eq(headers)
        expect(csv[3][0]).to eq("All facilities")
        expect(csv[3][4]).to eq("All")
        expect(csv[5][0]).to eq("Community facilities")
        expect(csv[5][4]).to eq("Community")
        expect(csv[7].slice(0, 5)).to eq(["1", "Block 1 - alphabetically first", "Facility 1", "PHC", "Community"])
        expect(csv[8].slice(0, 5)).to eq(["2", "Block 2 - alphabetically second", "Facility 2", "PHC", "Community"])
      end
    end

    context "Diabetes" do
      let(:service) {
        described_class.new(exporter: MonthlyDistrictData::Diabetes.new(
          region: @region,
          period: @period,
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

      it "includes the section name and headers" do
        result = service.report
        csv = CSV.parse(result)
        expect(csv[0]).to eq(["Monthly facility data for #{@region.name} #{@period.to_date.strftime("%B %Y")}"])
        expect(csv[1]).to eq(sections)
        expect(csv[2]).to eq(headers)
        expect(csv[3][0]).to eq("All facilities")
        expect(csv[3][4]).to eq("All")
        expect(csv[5][0]).to eq("Community facilities")
        expect(csv[5][4]).to eq("Community")
      end
    end
  end
end
