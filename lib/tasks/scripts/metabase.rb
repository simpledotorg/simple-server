# This script is based on https://github.com/itmi-id/metabase-migration
# Since this uses the metabase API which can change over time, it's a good idea
# to test run this before running against production.
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
# 2. Run commands in a REPL. You'll need a source question and a collection
# in the destination env where the question should be copied to.
# load "lib/tasks/scripts/metabase.rb"
# Metabase.new.duplicate_question(90, 23, 2)
#
# The database_id can be found from the URL when you choose
# the DB from https://metabase-sandbox.simple.org/browse

require "net/http"

class Metabase
  def initialize
    @source_host = ENV.fetch("METABASE_SOURCE_HOST")
    @destination_host = ENV.fetch("METABASE_DESTINATION_HOST")
    @source_token = authentication_token(
      @source_host,
      ENV.fetch("METABASE_SOURCE_USERNAME"),
      ENV.fetch("METABASE_SOURCE_PASSWORD")
    )
    @destination_token = authentication_token(
      @destination_host,
      ENV.fetch("METABASE_DESTINATION_USERNAME"),
      ENV.fetch("METABASE_DESTINATION_PASSWORD")
    )
  end

  attr_reader :source_host, :destination_host, :source_token, :destination_token

  # Copies over a list of questions from a source env to a destination env.
  # question_ids is a list of integer question IDs
  # destination_collection_id is an integer ID of the collection in the destination env
  # destination_database_id is an integer ID of the database in the destination env
  def duplicate_questions(question_ids, destination_collection_id, destination_database_id)
    question_ids.each do |question_id|
      duplicate_question(question_id, destination_collection_id, destination_database_id)
    end
  end

  def duplicate_question(question_id, destination_collection_id, destination_database_id, destination_question_name = nil)
    question = get_question(source_host, source_token, question_id)
    unless sql_question?(question)
      puts "Non SQL questions aren't supported question ID: #{question_id}"
      return
    end

    duplicate_question_payload = question.deep_merge(
      "dataset_query" => {"database" => destination_database_id},
      "collection_id" => destination_collection_id,
      "name" => destination_question_name || question["name"]
    )

    duplicate_question = create_question(destination_host, destination_token, duplicate_question_payload)
    puts "Failed to duplicate question #{question_id}" unless duplicate_question["creator"].present?

    log_successful_duplication(question, duplicate_question, destination_collection_id)
  end

  def authentication_token(host, username, password)
    path = "/api/session"
    response = post(host, nil, path, {username: username, password: password})
    puts "Successfully authenticated to #{host}" if response["id"].present?
    response["id"]
  end

  # These IDs can be passed to duplicate_questions
  # to help duplicate questions in a dashboard
  def get_question_ids_from_dashboard(host, session_token, dashboard_id)
    path = "/api/dashboard/#{dashboard_id}"
    get(host, session_token, path)["ordered_cards"].map { |a| a["card"]["id"] }.compact
  end

  def get_question(host, session_token, question_id)
    path = "/api/card/#{question_id}"
    get(host, session_token, path)
  end

  def create_question(host, session_token, payload)
    path = "/api/card"
    post(host, session_token, path, payload)
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

  def log_successful_duplication(question, duplicate_question, destination_collection_id)
    result = {
      question: duplicate_question["name"],
      source_url: "https://#{source_host}/card/#{question["id"]}",
      question_id: duplicate_question["id"],
      question_url: "https://#{destination_host}/card/#{duplicate_question["id"]}",
      collection_id: destination_collection_id,
      collection_url: "https://#{destination_host}/collection/#{destination_collection_id}"
    }

    puts "\nQuestion duplicated:"
    pp result
  end
end
