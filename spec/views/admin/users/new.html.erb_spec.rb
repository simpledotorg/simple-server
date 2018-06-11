require 'rails_helper'

RSpec.describe "admin/users/new", type: :view do
  before(:each) do
    FactoryBot.create_list(:facility, 5)
    @facilities = Facility.all
    assign(:user, User.new(
      :name => "MyString",
      :phone_number => "MyString",
      :security_pin_hash => "MyString"
    ))
  end

  it "renders new user form" do
    render

    assert_select "form[action=?][method=?]", admin_users_path, "post" do

      assert_select "input[name=?]", "user[name]"

      assert_select "input[name=?]", "user[phone_number]"

      assert_select "input[name=?]", "user[security_pin_hash]"
    end
  end
end
