class Api::V1::Schema < Api::Current::Schema

  class << self
    def processed_since
      Api::Current::Models.timestamp.merge(
        name: 'processed_since',
        description: 'The timestamp since which records have been processed by the server.
                    Use the server returned value in the next request to continue fetching records.'
      )
    end

    def sync_to_user_request
      [processed_since.merge(in: :query),
       { in: :query, name: :limit, type: :integer,
         description: 'Number of record to retrieve (a.k.a batch-size)' }]
    end

    def sync_to_user_response(response_key, schema_type = response_key)
      { type: :object,
        properties: {
          response_key => { '$ref' => "#/definitions/#{schema_type}" },
          :processed_since => { '$ref' => '#/definitions/processed_since' } },
        required: [response_key, :processed_since] }
    end

    def all_definitions
      Api::Current::Schema.definitions
        .merge(Api::V1::Models.definitions)
        .merge({ processed_since: processed_since })
        .except(:process_token)
    end
  end
end
