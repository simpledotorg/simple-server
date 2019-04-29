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

    def swagger_doc(version, definitions)
      {
        swagger: '2.0',
        basePath: "/api/#{version}",
        produces: ['application/json'],
        consumes: ['application/json'],
        schemes: ['https'],
        info: swagger_info(version),
        paths: {},
        definitions: definitions,
        securityDefinitions: security_definitions
      }
    end

    def swagger_docs
      {
        'current/swagger.json' => swagger_doc(:v3, Api::Current::Schema.all_definitions),
        'v2/swagger.json' => swagger_doc(:v2, Api::V2::Schema.all_definitions),
        'v1/swagger.json' => swagger_doc(:v1, Api::V1::Schema.all_definitions)
      }
    end
  end
end