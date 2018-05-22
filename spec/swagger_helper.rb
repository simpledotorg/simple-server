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

## Sync

### Why it needs to exist

Network connectivity on phones in rural
areas can be low, and patchy. So, the app needs to work offline,
as much as possible. The sync mechanism exists to allow sharing
records of patients, blook pressures, etc across devices.

### Levers

Physical resource constraints such as battery life, or network
are not under our control. In order for the app to adapt
well to the constraints, we need to have knobs on:

1. Batch size: how many records to send or fetch
2. Sync frequency: how often sending or fetchin happens

Preferably, these levers are modifyable at run-time, per device.

### Mechanism

1. Send records from device to server

The device needs to keep track of records that need to be
synced. These can be new records, or records that have one or more
fields updated. These records need to be formatted into the payload
schemas as defined in the individual APIs below. The API does not
differentiate between new and updated records; this is handled by the
server.  These payloads then need to be sent in batches, where each
batch is inherently independent of the previous one. However, it is
important to _send_ all records that need syncing, before fetching
records from the server.

2. Fetch records from server to device

When fetching records for the first time, the `first_time` query
parameter should be set. The server will then send back a number of
records as defined by the `number_of_records` query parameter. This is
essentially the "batch_size". The first response also includes a
`latest_record_timestamp`, that needs to be sent with the next
request, in order to retrieve more records from the server. If there
are no more records to be sent from the server, it returns an empty
list.

3. Merge records on device

The server may send back the same record multiple times. The merging
functionality on the device needs to be idempotent for this reason.

### Caveats

The computation of records to be sent is currently based on the
`updated_on_server_at` field on the server, and the
`latest_record_timestamp` in the query parameters. This implies, that
if there are multiple records with the same timestamp, the same record
will be sent multiple times. And if there are as many records with the
same timestamp as the batch size, the same response is sent over and
over again, effectively breaking the batching mechanism.

This implies we need sequencing of records on the server. We rely on
timestamps for this now. But we could have a separate sequence, or an
immutable and sequenced audit log to do this.
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
