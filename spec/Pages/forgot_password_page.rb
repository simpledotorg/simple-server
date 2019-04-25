
class ForgotPassword
  include Capybara::DSL


  def emailTextBox
    find(:id, "admin_email")
  end

  def resetPasswordButton
    find('input', :class => 'btn btn-primary')
  end

  def message
    find(:xpath,"//div[@class='alert alert-primary alert-dismissable fade show']")
  end

  def login
    find(:xpath, "//div/a[@href='/admins/sign_in']")
  end

  def messageCrossBtn
    find(:xpath, '//button[@class="close"]/span')
  end

  def unlockInstructionLink
    find(:xpath, "//a[@href='/admins/unlock/new']")
  end

  def resendInstructionButton
    find('input', :class => 'btn btn-primary')
  end

  def doResetPassword(email)
    emailTextBox.set(email)
    resetPasswordButton.click
    message.visible?
    messageCrossBtn.click
  end


  def resendUnlockInstruction(email)
    unlockInstructionLink.click
    emailTextBox.set(email)
    resendInstructionButton.click
    #assertion pending because of defect
  end


end