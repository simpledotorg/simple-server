class Hash
  def with_int_timestamps
    ['created_at', 'updated_at', 'updated_on_server_at'].each do |key|
      self[key] = self[key].to_i if self[key].present?
    end
    self
  end
end