# This script is based on https://github.com/itmi-id/metabase-migration
# Since this uses the metabase API which can change over time, it's a good idea
# to test run this before running against production.
#
# You'll need a source question, and a collection in the destination env
# where the question should be copied to.
#
# 1. Set credentials in your local .env
# METABASE_SOURCE_HOST=metabase-sandbox.simple.org
# METABASE_SOURCE_USERNAME=prabhanshu@nilenso.com
# METABASE_SOURCE_PASSWORD=password
# METABASE_DESTINATION_HOST=metabase.simple.org
# METABASE_DESTINATION_USERNAME=prabhanshu@nilenso.com
# METABASE_DESTINATION_PASSWORD=password
#
# Hostnames shouldn't have the http:// or https:// prefix.
#
# 2. Run commands in a REPL
# Metabase.new
# instance.duplicate_question(90, 23, 2)
# instance.duplicate_question(<question_id>, <destination_collection_id>, <destination_database_id>)
#
# The database_id can be found from the URL when you choose
# the DB from https://metabase-sandbox.simple.org/browse

require "net/http"

class Metabase
  def initialize(source_host = ENV["METABASE_SOURCE_HOST"],
    source_username = ENV["METABASE_SOURCE_USERNAME"],
    source_password = ENV["METABASE_SOURCE_PASSWORD"],
    destination_host = ENV["METABASE_DESTINATION_HOST"],
    destination_username = ENV["METABASE_DESTINATION_USERNAME"],
    destination_password = ENV["METABASE_DESTINATION_PASSWORD"])

    @source_host = source_host
    @destination_host = destination_host
    @source_token = authentication_token(@source_host, source_username, source_password)
    @destination_token = authentication_token(@destination_host, destination_username, destination_password)
  end

  # Copies over a list of questions from a source env to a destination env.
  # question_ids is a list of integer question IDs
  # destination_collection_id is an integer ID of the collection in the destination env
  # destination_database_id is an integer ID of the database in the destination env
  def duplicate_questions(question_ids, destination_collection_id, destination_database_id)
    question_ids.map do |question_id|
      duplicate_question(question_id, destination_collection_id, destination_database_id)
    end
  end

  def duplicate_question(question_id, destination_collection_id, destination_database_id, destination_question_name: nil)
    question = get_question_from_source(question_id)
    raise "Non SQL questions aren't supported question ID: #{question_id}" unless sql_question?(question)

    duplicate_question_payload = question.deep_merge(
      "dataset_query" => {"database" => destination_database_id},
      "collection_id" => destination_collection_id,
      "name" => destination_question_name || question["name"]
    )

    response = post(@destination_host, @destination_token, "/api/card", duplicate_question_payload)
    puts "Failed to duplicate question #{question_id}" unless response["creator"].present?

    puts "Question duplicated to https://#{@destination_host}/card/#{response["id"]}"
    puts "View collection at https://#{@destination_host}/collection/#{destination_collection_id}"
  end

  def authentication_token(host, username, password)
    path = "/api/session"
    response = post(host, nil, path, {username: username, password: password})
    puts "Successfully authenticated to #{host}" if response["id"].present?
    response["id"]
  end

  def get_question_from_source(question_id)
    path = "/api/card/#{question_id}"
    get(@source_host, @source_token, path)
  end

  def get(host, session_token, path)
    http = Net::HTTP.new(host, 443)
    http.use_ssl = true
    request = Net::HTTP::Get.new(path)
    request["X-Metabase-Session"] = session_token if session_token.present?
    JSON.parse(http.request(request).body)
  end

  def post(host, session_token, path, body)
    http = Net::HTTP.new(host, 443)
    http.use_ssl = true
    request = Net::HTTP::Post.new(path, "Content-Type" => "application/json")
    request.body = body.to_json
    request["X-Metabase-Session"] = session_token if session_token.present?
    JSON.parse(http.request(request).body)
  end

  def sql_question?(question)
    question["dataset_query"]["native"].present?
  end
end
