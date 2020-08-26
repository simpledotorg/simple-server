module Navigations
  class DashboardPageNavigation < ApplicationPage
    LOGOUT_BUTTON = {css: "a.logout"}.freeze
    MANAGE_OPTION = {xpath: "//li/div/a"}.freeze
    MAIN_MENU_TABS = {css: "ul.mr-auto>li>a"}.freeze
    PROFILE_DROPDOWN = {id: "navbarDropdown2"}.freeze

    def click_main_menu_tab(option)
      find(MAIN_MENU_TABS[:css], text: option).click
    end

    def select_main_menu_tab(option)
      find(:xpath, "//a[contains(text(),'" + option + "')]").click
    end

    def validate_owners_home_page
      main_menu_tabs = all_elements(MAIN_MENU_TABS)
      main_menu_tabs.each(&:visible?)
    end

    def select_manage_option(option)
      select_main_menu_tab("Settings")
      find(:xpath, "//a[text()='" + option + "']").click
    end

    def click_logout_button
      click(PROFILE_DROPDOWN)
      click(LOGOUT_BUTTON)
    end
  end
end
