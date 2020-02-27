require File.expand_path('../../config/environment', __dir__)

from = File.expand_path('data/golapganj.csv', __dir__)
to = File.expand_path('data/golapganj.csv.encrypted', __dir__)

key = ActiveSupport::KeyGenerator.new(ENV['BD_IMPORT_KEY']).generate_key(ENV['BD_IMPORT_SALT'], 32)
crypt = ActiveSupport::MessageEncryptor.new(key)
message = File.read(from)
encrypted_message = crypt.encrypt_and_sign(message)

File.open(to, 'w') do |f|
  f << encrypted_message
end
