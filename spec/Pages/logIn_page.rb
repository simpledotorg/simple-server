
class LoginPage
  include Capybara::DSL


  def emailTextBox
    find(:id, "admin_email")
  end

  def passwordTextBox
    find(:id, "admin_password")
  end

  def loginButton
    find('input', :class => 'btn btn-primary')
  end

  def rememberMeCheckbox
    find(:id, ":admin_remember_me")
  end

  def forgotPasswordLink
    find_link('Forgot your password?')
    # find('a', :text => ' Forgot your password?')
  end

  def unlockInstructionLink
    find('a', :href => '/admins/unlock/new')
  end

  def logInLink
    find('a', :class => "nav-link")
  end

  def errorMessage
    find(:xpath,'//div[@class="alert alert-warning alert-dismissable fade show"]')
  end

  def messageCrossBtn
    find(:xpath, '//button[@class="close"]/span')
  end

  def succefulLogoutMessage
    find(:xpath, '//div[@class="alert alert-primary alert-dismissable fade show"]')
  end


  def doLogin(emailID,password)
    emailTextBox.set(emailID)
    passwordTextBox.set(password)
    loginButton.click
  end



end
