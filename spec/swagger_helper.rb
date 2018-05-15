require 'rails_helper'
require 'api/spec'

extend Spec

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's confiugred to server Swagger from the same folder
  config.swagger_root = Rails.root.to_s + '/swagger'

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:to_swagger' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    'v1/swagger.json' => {
      swagger:     '2.0',
      basePath: '/api/v1',
      info: {
        description: 'API specification for RedApp Server',
        version: 'v1',
        title: 'RedApp Server',
        contact: {
          email: 'eng-backend@resolvetosavelives.org'
        },
        license: {
          name: 'MIT',
          url: 'https://github.com/resolvetosavelives/redapp-server/blob/master/LICENSE'
        }
      },
      paths:       {},
      definitions: all_definitions
    }
  }
end
