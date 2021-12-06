module Flipperable
  def flipper_id
    "#{self.class.name};#{id}"
  end

  def feature_enabled?(name)
    Flipper.enabled?(name, self)
  end

  def enable_feature(name)
    Flipper.enable(name, self)
  end

  def disable_feature(name)
    Flipper.disable(name, self)
  end
end
