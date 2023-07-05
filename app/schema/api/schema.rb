class Api::Schema
  class << self
    def swagger_info(version)
      {
        :description => I18n.t("api.documentation.description"),
        :version => version.to_s,
        :title => I18n.t("api.documentation.title"),
        "x-logo" => {
          url: ActionController::Base.helpers.image_path(I18n.t("api.documentation.logo.image")),
          backgroundColor: I18n.t("api.documentation.logo.background_color")
        },
        :contact => {
          email: I18n.t("api.documentation.contact.email")
        },
        :license => {
          name: I18n.t("api.documentation.license.name"),
          url: I18n.t("api.documentation.license.url")
        }
      }
    end

    def security_definitions
      {
        access_token: {
          type: "http",
          scheme: "bearer"
        },
        user_id: {
          type: "apiKey",
          in: "header",
          name: "X-USER-ID"
        },
        facility_id: {
          type: "apiKey",
          in: "header",
          name: "X-FACILITY-ID"
        },
        patient_id: {
          type: "apiKey",
          in: "header",
          name: "X-PATIENT-ID"
        }
      }
    end

    def import_api_security_definitions
      {
        import_auth: {
          type: :oauth2,
          flow: :application,
          tokenUrl: "/oauth/token",
          scopes: {"write" => "modify resources belonging to an organisation"}
        }
      }
    end

    def swagger_doc(version, definitions)
      {
        swagger: "2.0",
        basePath: "/api/#{version}",
        produces: ["application/json"],
        consumes: ["application/json"],
        schemes: ["https"],
        info: swagger_info(version),
        paths: {},
        definitions: definitions,
        securityDefinitions: security_definitions
      }
    end

    def swagger_for_import_api
      {
        swagger: "2.0",
        basePath: "/api/v4/",
        produces: ["application/json"],
        consumes: ["application/json"],
        schemes: ["https"],
        info: swagger_info(:import)
          .merge!(description: I18n.t("api.documentation.import_description")), # FIXME
        paths: {},
        definitions: Api::V4::Imports.all_definitions,
        securityDefinitions: import_api_security_definitions
      }
    end

    def swagger_docs
      {
        "v4/swagger.json" => swagger_doc(:v4, Api::V4::Schema.all_definitions),
        "v3/swagger.json" => swagger_doc(:v3, Api::V3::Schema.all_definitions),
        "v4/import.json" => swagger_for_import_api
      }
    end
  end
end
