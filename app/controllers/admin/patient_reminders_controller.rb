class Admin::PatientRemindersController < AdminController
  def index
    authorize { current_admin.power_user? }

    @languages = languages
  end

  def edit
    authorize { current_admin.power_user? }
  end

  def update
    authorize { current_admin.power_user? }
  end

  private

  def languages
    default = Facility::LOCALE_MAP["default"]
    country_name = CountryConfig.current[:name]
    country_languages = Facility::LOCALE_MAP[country_name.downcase].values

    [
      default,
      *country_languages
    ].uniq
  end
end
