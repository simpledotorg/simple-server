class DataScript
  attr_reader :logger

  def initialize(dry_run: true)
    @dry_run = dry_run
    @logger = Rails.logger
    RequestStore[:readonly] = true if dry_run?
    logger.info "Creating #{self.class} with dry_run=#{dry_run?}"
  end

  def dry_run?
    !!@dry_run
  end

  def run_safely
    return true if dry_run?
    yield
  end
end
