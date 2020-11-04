# Wraps a Region object and allows us to easily avoid persistence
# methods when we are exercising Regions in a backfill dry_run scenario
class DryRunRegion < SimpleDelegator
  attr_reader :logger

  def initialize(region, dry_run:, logger:)
    super(region)
    @dry_run = dry_run
    @logger = logger
    @region = region
    logger.info msg: "initialize", region: log_payload
  end

  def dry_run?
    @dry_run
  end

  def save_or_check_validity
    result = if dry_run?
      valid?
    else
      @region.save
    end
    logger.info msg: "save", result: result, region: log_payload, valid: result, errors: errors.full_messages.join(",")
    result
  end

  def save
    raise ArgumentError, "call save_or_check_validity instead"
  end

  def save!
    raise ArgumentError, "call save_or_check_validity instead"
  end
end
