# frozen_string_literal: true

class CreateDrRaiCustomIndicator < ActiveRecord::Migration[6.1]
  def up
    DrRai::CustomIndicator.find_or_create_by!(type: "DrRai::CustomIndicator")
  end

  def down
    DrRai::CustomIndicator.where(type: "DrRai::CustomIndicator").delete_all
  end
end
