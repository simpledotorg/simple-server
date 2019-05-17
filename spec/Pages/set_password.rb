class SetPassword < ApplicationPage
  include Capybara::DSL

  PASSWORD={id: "admin_password"}
  PASSWORD_CONFIRMATION={id: "admin_password_confirmation"}
  SET_MY_PASSWORD={xpath: "//input[@class='btn btn-primary']"}

  def set_password(password)
    type(PASSWORD,password)
    type(PASSWORD_CONFIRMATION,password)
    click(SET_MY_PASSWORD)
  end
end
