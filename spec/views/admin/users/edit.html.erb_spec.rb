require 'rails_helper'

RSpec.describe "admin/users/edit", type: :view do
  before(:each) do
    @user = assign(:user, User.create!(
      :name => "MyString",
      :phone_number => "MyString",
      :security_pin_hash => "MyString"
    ))
  end

  it "renders the edit user form" do
    render

    assert_select "form[action=?][method=?]", admin_user_path(@user), "post" do

      assert_select "input[name=?]", "user[name]"

      assert_select "input[name=?]", "user[phone_number]"

      assert_select "input[name=?]", "user[security_pin_hash]"
    end
  end
end
