require 'rails_helper'

extend Api::V1::Spec

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
      produces: ['application/json'],
      consumes: ['application/json'],
      schemes: ['https'],
      info: {
        description:'# API specification for RedApp
## Sync APIs
This API spec documents the endpoints that the devices (that are offline to varying levels) will use to sync data. The sync end points will send and receive bulk (a list of) entities. Both sending and receiving can be batched with configurable batch-sizes to accommodate low network bandwidth situations.
## Nesting resources
The APIs have been designed to provide an optimal balance between accuracy and simplicity. Some of the APIs (patients) will be nested, and some other (blood pressures) will be flat.
## Authentication
TODO

## Sync Mechanism
Refer to the [related ADR](https://github.com/resolvetosavelives/redapp-server/blob/master/doc/arch/001-synchronization.md).
',
        version: 'v1',
        title: 'RedApp Server',
        'x-logo' => {
          url: 'https://static1.squarespace.com/static/59945d559f7456b755d759f2/t/59aebc5ecf81e0ac9b4b6f59/1526304079797/?format=1500w',
          backgroundColor: '#FFFFFF'
        },
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
