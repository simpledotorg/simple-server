class HomePage
  include Capybara::DSL

  def logoutButton
    find(:xpath, "//a[text()='Logout']")
  end

  def clickLogoutButton
    logoutButton.click
  end

  def manageOption
    all(:xpath,"//li/div/a")
  end

  def mainMenuTabs
    all(:xpath, '//ul/li/a')
  end


  def selectMainMenuTab(option)
    mainMenuTabs.each do |tab|
      if tab.text.include? option
        tab.click
      end

    end
  end

  def validateOwnersHomePage
    mainMenuTabs.each do |tab|
      tab.visible?
    end
  end


  def selectManageOption(option)
    selectMainMenuTab("Manage")
    manageOption.each do |tab|
      if tab.text.include? option
        tab.click
      end

    end

  end

  end