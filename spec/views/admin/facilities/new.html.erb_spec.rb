require 'rails_helper'

RSpec.describe "admin/facilities/new", type: :view do
  before(:each) do
    assign(:facility, Facility.new(
      :name => "MyString",
      :street_address => "MyString",
      :village_or_colony => "MyString",
      :district => "MyString",
      :state => "MyString",
      :country => "MyString",
      :pin => "MyString",
      :facility_type => "MyString"
    ))
  end

  it "renders new facility form" do
    render

    assert_select "form[action=?][method=?]", admin_facilities_path, "post" do

      assert_select "input[name=?]", "facility[name]"

      assert_select "input[name=?]", "facility[street_address]"

      assert_select "input[name=?]", "facility[village_or_colony]"

      assert_select "input[name=?]", "facility[district]"

      assert_select "input[name=?]", "facility[state]"

      assert_select "input[name=?]", "facility[country]"

      assert_select "input[name=?]", "facility[pin]"

      assert_select "input[name=?]", "facility[facility_type]"
    end
  end
end
