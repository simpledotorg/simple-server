module Flipperable
  def flipper_id
    "#{self.class.name};#{id}"
  end

  def feature_enabled?(name)
    Flipper.enabled?(name, self)
  end
end
