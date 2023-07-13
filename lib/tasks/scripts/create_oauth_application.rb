module CreateOAuthApplication
  def self.create(name, client_id, client_secret)
    Doorkeeper::Application.create!(name: name, uid: client_id, secret: client_secret, scopes: "write")
  end
end
