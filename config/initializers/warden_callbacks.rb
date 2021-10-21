Warden::Manager.after_set_user do |email_auth, auth, opts|
  RequestStore.store[:current_user] = email_auth&.user&.to_datadog_hash if email_auth.respond_to?(:user)
end
