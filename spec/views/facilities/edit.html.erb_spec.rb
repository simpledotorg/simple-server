require 'rails_helper'

RSpec.describe "facilities/edit", type: :view do
  before(:each) do
    @facility = assign(:facility, Facility.create!(
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

  it "renders the edit facility form" do
    render

    assert_select "form[action=?][method=?]", facility_path(@facility), "post" do

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
