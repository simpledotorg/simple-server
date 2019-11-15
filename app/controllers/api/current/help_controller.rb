class Api::Current::HelpController < APIController
  layout false

  skip_before_action :current_user_present?, only: [:show]
  skip_before_action :validate_sync_approval_status_allowed, only: [:show]
  skip_before_action :authenticate, only: [:show]
  skip_before_action :validate_facility, only: [:show]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:show]

  HELP_TRANSLATIONS_GLOB = 'config/locales/api/help/*.html'
  before_action :set_html_translations

  def show
  end

  private

  def set_html_translations
    Dir.glob(HELP_TRANSLATIONS_GLOB)
        .each do |translation_file|
      locale = Pathname.new(translation_file).basename('.html').to_s.dasherize.to_sym
      unless I18n.backend.translations.dig(locale, :api, :help, :body_html).present?
        I18n.backend.store_translations(locale, { api: { help: { body_html: File.read(translation_file) } } })
      end
    end
  end
end
