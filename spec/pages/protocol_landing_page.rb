class ProtocolLandingPage < ApplicationPage

  ADD_NEW_PROTOCOL = { css: "a.btn-primary" }

  def click_add_new_protocol
    click(ADD_NEW_PROTOCOL)
  end

  def click_edit_protocol_link(name)
    find(:xpath, "//a[text()='#{name}']/../../..//a[contains(@class,'btn-outline-primary')]").click
  end
end