module CreateOAuthApplication
  def self.create(name, machine_user, client_id, client_secret)
    Doorkeeper::Application.create!(name: name, owner: machine_user, uid: client_id, secret: client_secret, scopes: "write")
  end
end
