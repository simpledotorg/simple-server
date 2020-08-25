module FlipperHelpers
  def enable_flag(*args)
    allow_any_instance_of(Flipper).to receive(:enabled?).with(*args).and_return(true)
  end

  def disable_flag(*args)
    allow_any_instance_of(Flipper).to receive(:enabled?).with(*args).and_return(false)
  end

  def with_flag_enabled(*args)
    enable_flag(*args)
    yield
    disable_flag(*args)
  end
end
