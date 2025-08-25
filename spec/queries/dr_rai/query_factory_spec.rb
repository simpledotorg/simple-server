require "rails_helper"

describe DrRai::QueryFactory do
  around do |xmpl|
    with_reporting_time_zone { xmpl.run }
  end

  describe "setup" do
    context "without dates" do
      it "sets date boundaries to 1 year from today" do
        qf = DrRai::QueryFactory.new(nil, nil)
        expect(qf.from_date).to eq 1.year.ago.to_date
        expect(qf.to_date).to eq Date.today
      end
    end
  end
end
