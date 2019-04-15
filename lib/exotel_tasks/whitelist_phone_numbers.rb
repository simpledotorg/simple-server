module ExotelTasks
  class WhitelistPhoneNumbers
    CUSTOMER_WHITELIST_API = "https://api.exotel.com/v1/Accounts/resolvetosavelives/CustomerWhitelist.json"

    attr_reader :stats

    def initialize(account_sid, token, data_file)
      @account_sid = account_sid
      @token = token
      @data_file = data_file

      @stats = { 'Total' => 0,
                 'Duplicate' => 0,
                 'Processed' => 0,
                 'Succeeded' => 0,
                 'Redundant' => 0,
                 'Failed' => 0 }
    end

    def rearrange_in_batches(batch_size)
      comma_separate_each_batch(extract_phone_nums_in_batches(parse_json_file, batch_size))
    end

    def update_stats(new_stats)
      @stats.merge!(new_stats.slice('Total',
                                    'Duplicate',
                                    'Processed',
                                    'Succeeded',
                                    'Redundant',
                                    'Failed')) { |_, v1, v2| v1 + v2 }
    end

    def process(body_params)
      logger.tagged('ExotelTasks::WhitelistPhoneNumbers#process') do
        begin
          response = HTTP
                       .basic_auth(user: @account_sid, pass: @token)
                       .post(CUSTOMER_WHITELIST_API, :params => body_params)

          if response.status.ok?
            update_stats(JSON.parse(response)['Result'])
            logger.debug("Response was successful. Current Current processing status: #{stats}")
          else
            logger.debug("Response was #{response.status}. Current processing status: #{stats}")
          end
        rescue HTTP::Error => _
          logger.debug("There was a HTTP error while making the call. Batch of #{body_params} is discarded.")
        end
      end
    end

    private

    def parse_json_file
      JSON.parse(File.read(@data_file),
                 symbolize_names: true)
    end

    def extract_phone_nums_in_batches(data, batch_size)
      data
        .map { |m| m[:number] }
        .in_groups_of(batch_size)
        .map(&:compact)
    end

    def comma_separate_each_batch(batched_phone_nums)
      batched_phone_nums.map { |batch| batch.join(',') }
    end
  end
end
