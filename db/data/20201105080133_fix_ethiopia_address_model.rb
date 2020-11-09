class FixEthiopiaAddressModel < ActiveRecord::Migration[5.2]
  def up
    # This migration should only run in Ethiopia environments
    unless ENV["DEFAULT_COUNTRY"] == "ET"
      return
    end

    Facility.find_each do |facility|
      current_zone = facility.zone
      current_district = facility.district

      facility.zone = current_district
      facility.district = current_zone
      facility.save
    end

    Address.find_each do |address|
      current_zone = address.zone
      current_district = address.district

      address.zone = current_district
      address.district = current_zone
      address.save
    end
  end

  def down
    # This migration should only run in Ethiopia environments
    unless ENV["DEFAULT_COUNTRY"] == "ET"
      return
    end

    Facility.find_each do |facility|
      current_zone = facility.zone
      current_district = facility.district

      facility.zone = current_district
      facility.district = current_zone
      facility.save
    end

    Address.find_each do |address|
      current_zone = address.zone
      current_district = address.district

      address.zone = current_district
      address.district = current_zone
      address.save
    end
  end
end
