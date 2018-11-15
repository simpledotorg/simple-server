class Api::Schema
  class << self
    def swagger_info(version)
      {
        description: I18n.t('api.documentation.description'),
        version: version.to_s,
        title: I18n.t('api.documentation.title'),
        'x-logo' => {
          url: ActionController::Base.helpers.image_path(I18n.t('api.documentation.logo.image')),
          backgroundColor: I18n.t('api.documentation.logo.background_color')
        },
        contact: {
          email: I18n.t('api.documentation.contact.email')
        },
        license: {
          name: I18n.t('api.documentation.license.name'),
          url: I18n.t('api.documentation.license.url')
        }
      }
    end

    def security_definitions
      { basic: {
        type: :basic
      } }
    end

    def swagger_docs
      {
        'v2/swagger.json' => {
          swagger: '2.0',
          basePath: '/api/v2',
          produces: ['application/json'],
          consumes: ['application/json'],
          schemes: ['https'],
          info: swagger_info(:v2),
          paths: {},
          definitions: Api::Current::Schema.all_definitions,
          securityDefinitions: security_definitions
        },
        'v1/swagger.json' => {
          swagger: '2.0',
          basePath: '/api/v1',
          produces: ['application/json'],
          consumes: ['application/json'],
          schemes: ['https'],
          info: swagger_info(:v1),
          paths: {},
          definitions: Api::V1::Schema.all_definitions,
          securityDefinitions: security_definitions
        }
      }
    end
  end
end