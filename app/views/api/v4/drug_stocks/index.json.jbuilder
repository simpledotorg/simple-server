json.month @for_end_of_month.strftime("%Y-%m")
json.facility_id @current_facility.id
json.drug_stock_form_url @drug_stock_form_url
json.drugs @drug_stocks do |drug_stock|
  json.protocol_drug_id drug_stock.protocol_drug_id
  json.in_stock drug_stock.in_stock
  json.received drug_stock.received
end
