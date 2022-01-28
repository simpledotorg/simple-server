class EmailAuthentications::SessionsController < Devise::SessionsController
  def destroy
    current_email_authentication.invalidate_all_sessions!
    super
  end
end
