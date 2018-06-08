require 'rails_helper'

RSpec.describe "admin/users/show", type: :view do
  before(:each) do
    @user = assign(:user, User.create!(
      :name => "Name",
      :phone_number => "Phone Number",
      :security_pin_hash => "Security Pin Hash",
      :facility_id => FactoryBot.create(:facility).id
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Phone Number/)
    expect(rendered).to match(/Security Pin Hash/)
  end
end
