
class DashboardPage
  include Capybara::DSL

  def organisationNames
    all(:xpath,"//th/h2")
  end

  def dashboard
    find(:xpath, "//a[text()='Dashboard']")
  end


  def getOrganisaitonCount
    return organisationNames.size
  end


end