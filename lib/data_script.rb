class DataScript
  def initialize(dry_run: true)
    @dry_run = dry_run
  end

  def dry_run?
    !!@dry_run
  end
end