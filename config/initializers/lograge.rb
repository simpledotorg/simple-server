Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Class.new do |fmt|
    def fmt.call(data)
      {msg: "request"}.merge(data)
    end
  end
end
