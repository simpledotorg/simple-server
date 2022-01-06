# frozen_string_literal: true

module AdminPage
  module FacilityGroups
    class New < ApplicationPage
      CREATE_FACILITY_GROUP_BUTTON = {css: "input[value='Save district']"}.freeze
      FACILITY_NAME = {id: "facility_name"}.freeze
      DELETE_FACILITY_GROUP_BUTTON = {css: "a.ml-4"}.freeze
      PROTOCOL_DROPDOWN = {xpath: "//select[@name='facility_group[protocol_id]']"}.freeze
      UNASSOCIATED_FACILITY_CHECKBOX = {css: "input[type='checkbox']"}.freeze
      SUCCESSFUL_MESSAGE = {css: "div.alert-primary"}.freeze
      MESSAGE_CROSS_BUTTON = {css: "button.close"}.freeze
      UPDATE_FACILITY_GROUP_BUTTON = {css: "input[value='Save district']"}.freeze

      def select_organisation_name_dropdown(value)
        find(:xpath, "//select[@name='facility_group[organization_id]']").find(:option, value).select_option
      end

      def select_state_dropdown(value)
        find(:xpath, "//select[@name='facility_group[state]']").find(:option, value).select_option
      end

      def select_medication_list_name_dropdown(value)
        find(:xpath, "//select[@name='facility_group[protocol_id]']").find(:option, value).select_option
      end

      def add_new_facility_group_without_assigning_facility(org_name:, name:, description:, protocol_name:, state: nil)
        select_organisation_name_dropdown(org_name)
        type(FACILITY_NAME, name)
        select_state_dropdown(state) if state
        select_medication_list_name_dropdown(protocol_name)
        click(CREATE_FACILITY_GROUP_BUTTON)
      end

      def add_new_facility_group(org_name:, name:, description:, protocol_name:, state: nil)
        select_organisation_name_dropdown(org_name)
        type(FACILITY_NAME, name)
        select_state_dropdown(state) if state
        select_medication_list_name_dropdown(protocol_name)
        click(CREATE_FACILITY_GROUP_BUTTON)
      end

      def click_on_delete_facility_group_button
        click(DELETE_FACILITY_GROUP_BUTTON)
        # page.accept_alert("OK")
        # present?(SUCCESSFUL_MESSAGE)
        # click(MESSAGE_CROSS_BUTTON)
      end

      def select_unassociated_facility(facility_name)
        within(:xpath, "//label[text()='Unassociated facilities']/..") do
          page.has_content?(facility_name)
          find(:xpath, "//div[@class='form-check']/label[text()='#{facility_name}']/../input").click
        end
      end

      def click_on_update_facility_group_button
        click(UPDATE_FACILITY_GROUP_BUTTON)
      end
    end
  end
end
