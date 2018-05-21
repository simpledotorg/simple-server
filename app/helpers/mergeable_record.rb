class MergeableRecord

  attr_reader :record
  attr_reader :status

  def initialize(record)
    @record = record
    @status = nil
  end

  def merge
    if @record.invalid?
      @status = :invalid
    elsif existing_record.nil?
      set_updated_on_server_at
      @status = :new
      @record = @record.class.create(@record.attributes)
    elsif @record.updated_at > existing_record.updated_at
      set_updated_on_server_at
      existing_record.update(@record.attributes)
      @status = :updated
      @record = existing_record
    else
      @status = :old
      @record = existing_record
    end
    self
  end

  def merged?
    %i[new updated].include? @status
  end

  private

  def existing_record
    @existing_record ||= @record.class.find_by(id: @record.id)
  end

  def set_updated_on_server_at
    @record.updated_on_server_at = Time.now
  end
end
