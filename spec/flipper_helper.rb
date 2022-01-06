# frozen_string_literal: true

module FlipperHelpers
  def enable_flag(*args)
    allow(Flipper).to receive(:enabled?).and_call_original
    allow(Flipper).to receive(:enabled?).with(*args).and_return(true)
  end

  def disable_flag(*args)
    allow(Flipper).to receive(:enabled?).and_call_original
    allow(Flipper).to receive(:enabled?).with(*args).and_return(false)
  end
end
