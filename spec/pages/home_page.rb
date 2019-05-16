class HomePage < Base
  include Capybara::DSL

  LOGOUT_BUTTON = {xpath: "//a[@class='nav-link']"}
  MANAGE_OPTION = {xpath: "//li/div/a"}
  MAIN_MENU_TABS = {xpath: '//ul/li/a'}

  def select_main_menu_tab(option)
    mainMenuTabs = all_elements(MAIN_MENU_TABS)
    mainMenuTabs.each {|tab| tab.click if tab.text.include? option}
  end

  def validate_home_page
    mainMenuTabs = all_elements(MAIN_MENU_TABS)
    mainMenuTabs.each {|tab| tab.visible?}
  end

  def select_manage_option(option)
    select_main_menu_tab("Manage")
    manageoption = all_elements(MANAGE_OPTION)
    manageoption.each {|tab| tab.click if tab.text.include? option}
  end

  def click_logout_button
    click(LOGOUT_BUTTON)
  end
end