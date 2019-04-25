
class CommonPage
  include Capybara::DSL


  def verifyText( element,message)
    element.text.include?(message)==true
  end


end