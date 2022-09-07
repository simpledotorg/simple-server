class Admin::PatientRemindersController < AdminController
  helper_method :default_message, :configured_message, :language_names

  before_action :set_configuration, only: [:edit, :update, :destroy]

  def index
    authorize { current_admin.power_user? }

    @languages = languages
    @messages = @languages.each_with_object({}) do |language, hash|
      hash[language] = configured_message(language) || default_message(language)
    end
  end

  def edit
    authorize { current_admin.power_user? }
  end

  def update
    authorize { current_admin.power_user? }

    message = configuration_params[:value]

    if message.blank?
      @configuration.destroy!
      redirect_to :admin_patient_reminders, notice: "Patient reminder for #{params[:id]} reset to default."
    else
      @configuration.value = message
      if @configuration.save
        redirect_to :admin_patient_reminders, notice: "Patient reminder for #{params[:id]} updated."
      else
        render :edit
      end
    end
  end

  def destroy
    authorize { current_admin.power_user? }

    @configuration.destroy

    redirect_to :admin_patient_reminders, notice: "Patient reminder for #{params[:id]} reset to default."
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

  def language_names
    {
      "en" => "English",
      "bn-BD" => "Bangla",
      "am-ET" => "Amharic",
      "om-ET" => "Oromo",
      "sid-ET" => "Sidama",
      "so-ET" => "Somali",
      "ti-ET" => "Tigrinya",
      "bn-IN" => "Bengali",
      "hi-IN" => "Hindi",
      "kn-IN" => "Kannada",
      "mr-IN" => "Marathi",
      "pa-Guru-IN" => "Punjabi",
      "ta-IN" => "Tamil",
      "te-IN" => "Telugu",
      "si-LK" => "Sinhala"
    }
  end

  def patient_reminder_key(language)
    "appointment_reminders.#{language}"
  end

  def configured_message(language)
    ::Configuration.fetch(patient_reminder_key(language))
  end

  def default_message(language)
    I18n.t('communications.appointment_reminders.sms', locale: language)
  end

  def set_configuration
    @configuration = ::Configuration.find_or_initialize_by(name: patient_reminder_key(params[:id]))
  end

  def configuration_params
    params.require(:configuration).permit(:value)
  end
end
