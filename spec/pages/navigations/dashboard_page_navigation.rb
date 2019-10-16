module Navigations
  class DashboardPageNavigation < ApplicationPage
    LOGOUT_BUTTON = { css: 'a.logout' }.freeze
    MAIN_MENU_TABS = { css: "ul.mr-auto>li>a" }.freeze
    PROFILE_DROPDOWN = { id: 'navbarDropdown2' }.freeze

    def click_main_menu_tab(option)
      find(MAIN_MENU_TABS[:css], text: option).click
    end

    def select_main_menu_tab(option)
      find(:xpath,"//a[contains(text(),'"+option+"')]").click
      # mainMenuTabs = all_elements(MAIN_MENU_TABS)
      # mainMenuTabs.each do |tab|
      #   if tab.text.include? option
      #     tab.click
      #   end
      # end
    end

    def validate_owners_home_page
      mainMenuTabs = all_elements(MAIN_MENU_TABS)
      mainMenuTabs.each do |tab|
        tab.visible?
      end
    end

    def select_manage_option(option)
      select_main_menu_tab("Manage")
      find(:xpath,"//a[text()='"+option+"']").click
    end

    def click_logout_button
      click(PROFILE_DROPDOWN)
      click(LOGOUT_BUTTON)
    end
  end
end
