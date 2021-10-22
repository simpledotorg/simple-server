require "rails_helper"

describe Reports::RepositoryPresenter do
  it "create works" do
    region = create(:facility).region
    presenter = described_class.create(region, period: Reports.default_period)
    expect(presenter.to_hash(region).keys).to include(:adjusted_patient_counts_with_ltfu, :period_info)
  end
end
