class PatientsPage < ApplicationPage

  LOGOUT_BUTTON = { xpath: "//a[@class='nav-link']" }

  def click_logout_button
    click(LOGOUT_BUTTON)
  end
end