require 'rails_helper'

RSpec.describe "admin/users/index", type: :view do
  before(:each) do
    assign(:users, [
      User.create!(
        :name => "Name",
        :phone_number => "Phone Number",
        :security_pin_hash => "Security Pin Hash",
        :facility_id => FactoryBot.create(:facility).id
      ),
      User.create!(
        :name => "Name",
        :phone_number => "Phone Number",
        :security_pin_hash => "Security Pin Hash",
        :facility_id => FactoryBot.create(:facility).id
      )
    ])
  end

  it "renders a list of users" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Phone Number".to_s, :count => 2
    assert_select "tr>td", :text => "Security Pin Hash".to_s, :count => 2
  end
end
