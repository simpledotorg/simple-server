module FlipperHelpers
  def enable_flag(*args)
    allow_any_instance_of(Flipper).to receive(:enabled?).with(*args).and_return(true)
  end

  def disable_flag(*args)
    allow_any_instance_of(Flipper).to receive(:enabled?).with(*args).and_return(false)
  end
end
