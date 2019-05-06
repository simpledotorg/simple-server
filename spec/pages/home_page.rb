class HomePage < Base
  include Capybara::DSL

  LOGOUT_BUTTON={xpath: "//a[@class='nav-link']"}
  MANAGE_OPTION={xpath: "//li/div/a"}
  MAIN_MENU_TABS={xpath: '//ul/li/a'}

  def select_main_menu_tab(option)
    mainMenuTabs = all_elements(MAIN_MENU_TABS)
    mainMenuTabs.each do |tab|
      if tab.text.include? option
        tab.click
      end
    end
  end

  def validate_owners_home_page
    mainMenuTabs = all_elements(MAIN_MENU_TABS)
    mainMenuTabs.each do |tab|
      tab.visible?
    end
  end

  def select_manage_option(option)
    select_main_menu_tab("Manage")
    manageoption = all_elements(MANAGE_OPTION)
    manageoption.each do |tab|
      if tab.text.include? option
        tab.click
      end
    end
  end

  def click_logout_button
    click(LOGOUT_BUTTON)
  end
  end