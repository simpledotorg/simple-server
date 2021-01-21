Warden::Manager.after_set_user do |email_auth, auth, opts|
  RequestStore.store[:current_user_id] = email_auth&.user&.id if email_auth.respond_to?(:user)
end
