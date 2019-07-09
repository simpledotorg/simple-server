class OrganizationsPage < ApplicationPage

  ADD_NEW_ORGANIZATION_BUTTON = { css: 'a.btn.btn-sm.btn-primary' }.freeze
  ORGANIZATION_NAME_TEXT_FIELD = { id: 'organization_name' }.freeze
  ORGANIZATION_DESCRIPTION_TEXT_FIELD = { id: 'organization_description' }.freeze
  CREATE_ORGANIZATION_BUTTON = { css: 'input.btn.btn-primary'}.freeze
  ORG_NAME_LIST = { xpath: "//tr/td[1]" }.freeze

  def create_new_organization(orgName, orgDesc)
    click(ADD_NEW_ORGANIZATION_BUTTON)
    type(ORGANIZATION_NAME_TEXT_FIELD, orgName)
    type(ORGANIZATION_DESCRIPTION_TEXT_FIELD, orgDesc)
    click(CREATE_ORGANIZATION_BUTTON)
  end

  def verify_organization_info()
    orgnameList = all_elements(ORG_NAME_LIST)
    orgnameList.each do |name|
      name.text.include? 'test'
    end
  end
end