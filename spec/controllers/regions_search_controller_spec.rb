require 'rails_helper'

RSpec.describe RegionsSearchController, type: :controller do
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  before do
  end
  it "returns results" do
    @facility_group = create(:facility_group, organization: organization)
    @facility_1 = create(:facility, name: "Facility 1", block: "Block 1", facility_group: @facility_group)
    @facility_2 = create(:facility, name: "Facility 2", block: "Block 1", facility_group: @facility_group)
    # facility_group_1 = FactoryBot.create(:facility_group, name: "East Market", organization: organization)
    # facility_group_2 = FactoryBot.create(:facility_group, name: "West Market", organization: organization)
    # pp facility_group_1.region

    sign_in(cvho.email_authentication)
    get :show, params: {query: "Fac"}
    expect(response).to be_successful
    expect(assigns(:results)).to_not be_empty
    expect(assigns(:results)).to contain_exactly(@facility_1.region, @facility_2.region)
  end

end
