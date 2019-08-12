class DashboardPageNavigation < ApplicationPage
  LOGOUT_BUTTON = { css: 'a.dropdown-item[href="/admins/sign_out"]'}.freeze
  MANAGE_OPTION = { xpath: "//li/div/a"}.freeze
  MAIN_MENU_TABS = { css: "ul.mr-auto>li>a" }.freeze
  PROFILE_DROPDOWN= {id: 'navbarDropdown2'}.freeze

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
    manage_option = all_elements(MANAGE_OPTION)
    manage_option.each do |tab|
      if tab.text.include? option
        tab.click
      end
    end
  end

  def click_logout_button
    click(PROFILE_DROPDOWN)
    click(LOGOUT_BUTTON)
  end
end
