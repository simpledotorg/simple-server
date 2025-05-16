class CustomSwaggerController < ApplicationController
  def show
    version = params[:version]
    file_path = Rails.root.join("swagger", version, "swagger.json")

    unless File.exist?(file_path)
      render json: {error: "Swagger file for #{version} not found"}, status: :not_found and return
    end

    swagger_json = JSON.parse(File.read(file_path))

    # Inject brand-specific info
    swagger_json["info"]["title"] = Rails.configuration.application_brand_name.to_s
    swagger_json["info"]["description"] = "# API spec for #{Rails.configuration.application_brand_name}\n## Sync APIs\nThis API spec documents the endpoints that the devices (that are offline to varying levels) will use to sync data. The sync end points will send and receive bulk (a list of) entities. Both sending and receiving can be batched with configurable batch-sizes to accommodate low network bandwidth situations.\n\n## Nesting resources\nThe APIs have been designed to provide an optimal balance between accuracy and simplicity. Some of the APIs (patients) will be nested, and some other (blood pressures) will be flat.\n\n## Sync Mechanism\nRefer to the [related ADR](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/001-synchronization.md).\n\n## API Authentication\nThere are two types of authentication available to access different parts of the #{Rails.configuration.application_brand_name} API.\n- User Authentication - For medical professionals using the #{Rails.configuration.application_brand_name} App. Grants access to most of the #{Rails.configuration.application_brand_name} API\n  to read and write data for communities of patients.\n- Patient authentication - For individual patients. Grants access to read a patient's own data.\n\n### User Authentication\n\nA #{Rails.configuration.application_brand_name} client can make authenticated requests to the #{Rails.configuration.application_brand_name} API on behalf of a medical professional with the\nfollowing three required credentials:\n- API Access Token\n- User ID\n- Facility ID\n\nIn order to obtain these credentials, a #{Rails.configuration.application_brand_name} client can authenticate a user with the following steps. The\nclient will need the user's registered phone number to perform the authentication.\n1. Submit the users phone number to the [`POST /v4/users/find` endpoint](#tag/User/paths/~1users~1find/post). If\na user exists with this phone number, the response will return their id.\n2. Submit the user's id retreived in the previous step, along with the user's password to the\n[`POST v4/users/activate` endpoint](#tag/User/paths/~1users~1activate/post).\nThis will validate the user's password, and trigger an OTP to be sent to the user's phone number.\n3. Submit the user's id, their password, and the OTP (received after the previous step) to the\n[`POST v3/login` endpoint](#tag/User-Login/paths/~1login/post). If the submitted otp and password are valid,\nthis will return an access token that can be used to authenticate the user. The access token will remain valid\nuntil the user signs into another device.\n\nOn successful authentication, the client will receive a payload containing an API access token and some user\ninformation.\nThe following headers need to be attached to subsequent requests as shown below.\n- `Authorization: Bearer <access token>`\n- `X-User-Id: <user ID>`\n- `X-Facility-Id: <facility ID>` This is the id for either the registration facility of the user, or another\nfacility in their facility group.\n\n### Patient Authentication\nA #{Rails.configuration.application_brand_name} client can make authenticated requests to the #{Rails.configuration.application_brand_name} API on behalf of a patient with the following\ncredentials:\n- API Access Token\n- Patient ID\n\nIn order to obtain these credentials, a #{Rails.configuration.application_brand_name} client can authenticate a patient with the following steps. The\nclient will need the patient's BP Passport UUID to perform the authentication.\n1. Submit the patient's BP Passport UUID to the [`POST /v4/patients/activate` endpoint](#tag/Patient/paths/~1patient~1activate/post).\n   This will trigger an OTP message to be sent to the patient's registered phone number.\n2. Submit the patient's BP Passport UUID and OTP (received after the previous step) to the [`POST /v4/patients/login` endpoint](#tag/Patient/paths/~1patient~1login/post)\n\nOn successful authentication, the client will receive a payload containing an API access token and a patient ID.\nBoth of these data points need to be attached to subsequent requests as request headers as shown below.\n- `Authorization: Bearer <access token>`\n- `X-Patient-Id: <patient ID>`\n\nThe API access token will remain valid until the patient signs into another device.\n\nThe comprehensive list of authentication mechanisms used is provided below. It lists the specific details of\nusing access tokens and other request headers to authenticate with the API.\n"
    swagger_json["info"]["contact"]["email"] = Rails.configuration.eng_email_id.to_s

    render json: swagger_json
  end

  def show_import
    version = params[:version]
    file_path = Rails.root.join("swagger", version, "import.json")

    unless File.exist?(file_path)
      render json: {error: "Swagger file for #{version} not found"}, status: :not_found and return
    end

    swagger_json = JSON.parse(File.read(file_path))

    # Inject brand-specific info
    swagger_json["info"]["title"] = Rails.configuration.application_brand_name.to_s
    swagger_json["info"]["description"] = "# API spec for #{Rails.configuration.application_brand_name}\nThis API spec documents the Import API for partner organizations that want to send their data to #{Rails.configuration.application_brand_name}. The API payloads are based on modified versions of [FHIR](http://hl7.org/fhir/R4/) specification resources.\n\n## Authorization\nAuthorization is done via OAuth 2.0, using the [Client Credential flow](https://www.oauth.com/oauth2-servers/access-tokens/client-credentials/). At the end of this flow, clients will receive an access token which is attached to all the requests to import data.\n\nWe recommend using popular open source [OAuth client libraries](https://oauth.net/code/) that will perform the flow in order to obtain the access token.\n"
    swagger_json["info"]["contact"]["email"] = Rails.configuration.eng_email_id.to_s
    swagger_json["paths"]["/import"]["put"]["summary"] = "Send bulk resources to #{Rails.configuration.application_brand_name}"
    swagger_json["definitions"]["patient"]["properties"]["name"]["description"] = "Full name of the patient. Client can send anonymised names. \
                          If name is unset, #{Rails.application.config.application_brand_name} will generate a random name."
    swagger_json["definitions"]["patient"]["properties"]["gender"]["description"] = "FHIR does not have a code for transgender, but #{Rails.application.config.application_brand_name} does.\
                    To accomodate this use case, we are considering 'other' to mean transgender."
    swagger_json["definitions"]["contact_point"]["properties"]["use"]["description"] = "Phone number type of the patient. \
                  Everything else other than \"mobile\" and \"old\", is marked as landline in #{Rails.application.config.application_brand_name}. \
                  \"old\" would mark the phone number as inactive."
    swagger_json["definitions"]["appointment"]["properties"]["status"]["description"] = "Status of appointment. Translation to #{Rails.application.config.application_brand_name} statuses:\n- pending: scheduled\n- fulfilled: visited\n- cancelled: cancelled\nThis is a subset of all valid status codes in the FHIR standard.\n"
    swagger_json["definitions"]["medication_request"]["properties"]["dosageInstruction"]["items"]["properties"]["timing"]["properties"]["code"]["description"] = "Mapping to #{Rails.application.config.application_brand_name} representation\nQD: OD (Once a day)\nBID: BD (Twice a day)\nTID: TDS (Thrice a day)\nQID: QDS (Four times a day)"
    swagger_json["definitions"]["appointment"]["properties"]["start"]["description"] = "Start datetime of appointment. #{Rails.application.config.application_brand_name} will truncate it to a date granularity."

    render json: swagger_json
  end
end
