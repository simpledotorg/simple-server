require 'rails_helper'

RSpec.describe RegionsSearchController, type: :controller do
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  it "returns results" do
    @facility_group = create(:facility_group, organization: organization)
    @facility_1 = create(:facility, name: "Facility 1", block: "Block 1", facility_group: @facility_group)
    @facility_2 = create(:facility, name: "Facility 2", block: "Block 1", facility_group: @facility_group)
    _facility_3 = create(:facility, name: "CHC other", block: "Block 1", facility_group: @facility_group)
    facility_4 = create(:facility, name: "Clinic", block: "Surface Block", facility_group: @facility_group)

    sign_in(cvho.email_authentication)
    get :show, params: {query: "Fac"}
    expect(response).to be_successful
    expect(assigns(:results)).to_not be_empty
    expect(assigns(:results)).to contain_exactly(@facility_1.region, @facility_2.region, @facility_4.block_region)
  end

end
