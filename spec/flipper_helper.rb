module FlipperHelpers
  def enable_flag(*args)
    allow(Flipper).to receive(:enabled?).and_call_original
    allow(Flipper).to receive(:enabled?).with(*args).and_return(true)
  end

  def disable_flag(*args)
    allow(Flipper).to receive(:enabled?).and_call_original
    allow(Flipper).to receive(:enabled?).with(*args).and_return(false)
  end

  def all_district_overview_enabled?
    Flipper.enabled?(:all_district_overview, current_admin) && params[:facility_group] == "all-districts"
  end
end
