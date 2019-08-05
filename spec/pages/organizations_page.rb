class OrganizationsPage < ApplicationPage

  ADD_NEW_ORGANIZATION_BUTTON = { css: 'nav.page-nav>a' }.freeze
  ORGANIZATION_NAME_TEXT_FIELD = { id: 'organization_name' }.freeze
  ORGANIZATION_DESCRIPTION_TEXT_FIELD = { id: 'organization_description' }.freeze
  CREATE_ORGANIZATION_BUTTON = { css: 'input.btn-primary'}.freeze
  ORGANIZATION_NAME = {css: "div.card" }.freeze

  def create_new_organization(orgName, orgDesc)
    click(ADD_NEW_ORGANIZATION_BUTTON)
    type(ORGANIZATION_NAME_TEXT_FIELD, orgName)
    type(ORGANIZATION_DESCRIPTION_TEXT_FIELD, orgDesc)
    click(CREATE_ORGANIZATION_BUTTON)
  end

  def is_organization_name_present(orgName)
    org_name = all_elements(ORGANIZATION_NAME)
    org_name.each do |name|
      name.text.include? orgName
    end
  end

  def delete_organization(org_name)
      within(:xpath ,"//a[text()='#{org_name}']/../../..") do
        find(:css ,'i.fa-trash-alt').click
      end
  end
end