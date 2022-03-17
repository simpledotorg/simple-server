module Navigations
  class DashboardPageNavigation < ApplicationPage
    LOGOUT_BUTTON = {css: "#nav-more-logout"}
    MAIN_MENU = {css: "#navigation"}
    MAIN_MENU_TABS = {css: ".nav-link"}
    MORE_DROPDOWN = {css: ".nav-link-dropdown"}

    def hover_nav
      find(MAIN_MENU[:css]).hover
    end

    def click_main_menu_tab(option)
      hover_nav
      find(MAIN_MENU_TABS[:css], text: option).click
    end

    def validate_owners_home_page
      main_menu_tabs = all_elements(MAIN_MENU_TABS)
      main_menu_tabs.each(&:visible?)
    end

    def open_more
      hover_nav
      find(MORE_DROPDOWN[:css]).click
    end

    def click_manage_option(option)
      hover_nav
      open_more
      find(option).click
    end

    def click_logout_button
      hover_nav
      find(LOGOUT_BUTTON[:css]).click
    end
  end
end
