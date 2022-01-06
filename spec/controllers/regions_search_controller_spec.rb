# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegionsSearchController, type: :controller do
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  render_views

  it "returns results" do
    @facility_group = create(:facility_group, organization: organization)
    @facility_1 = create(:facility, name: "Facility 1", block: "Block 1", facility_group: @facility_group)
    @facility_2 = create(:facility, name: "Facility 2", block: "Block 1", facility_group: @facility_group)
    _facility_3 = create(:facility, name: "CHC other", block: "Block 1", facility_group: @facility_group)
    facility_4 = create(:facility, name: "Clinic", block: "Surface Block", facility_group: @facility_group)
    block = facility_4.block_region
    expected = [@facility_1, @facility_2, block]

    sign_in(cvho.email_authentication)
    get :show, params: {query: "Fac"}

    expect(response).to be_successful
    results = JSON.parse(response.body)
    expect(results.size).to eq(expected.size)
    names = results.map { |r| r["name"] }
    expect(names).to match_array(expected.map(&:name))
  end

  it "no results found" do
    facility_group = create(:facility_group, organization: organization)
    _facility_1 = create(:facility, name: "Facility 1", block: "Block 1", facility_group: facility_group)

    sign_in(cvho.email_authentication)
    get :show, params: {query: "not found"}

    expect(response).to be_successful
    results = JSON.parse(response.body)
    expect(results).to eq([])
  end

  it "works with an empty query" do
    sign_in(cvho.email_authentication)
    get :show

    expect(response).to be_successful
  end
end
