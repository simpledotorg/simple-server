class OrganisaitonsPage

  include Capybara::DSL


  def addNewOrganisaitonButton
    find("a", :class => "btn btn-sm btn-primary")
  end

  def organizationNameTextField
    find(:id, "organization_name")
  end


  def organizationDescriptionTextField
    find(:id, "organization_description")
  end


  def createOrganisaitonButton
    find("input", :class => "btn btn-primary")
  end


  def createNewOrganisation()
    addNewOrganisaitonButton.click
    organizationNameTextField.set("test")
    organizationDescriptionTextField.set("testDescription")
    createOrganisaitonButton.click

  end

  def verifyOrganisationInfo()
    orgNameList = all(:xpath, "//tr/td[1]")
    orgNameList.each do |name|
      name.text.include?'test'
    end
  end
end