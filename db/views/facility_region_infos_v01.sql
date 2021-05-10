SELECT facilities.id,
       facility_region.id facility_region_id,
       facility_region.name facility_region_name,
       facility_region.slug facility_region_slug,
       block_region.id block_region_id,
       block_region.name block_region_name,
       block_region.slug block_region_slug,
       district_region.id district_region_id,
       district_region.name district_region_name,
       district_region.slug district_region_slug,
       state_region.id state_region_id,
       state_region.name state_region_name,
       state_region.slug state_region_slug,
       country_region.id country_region_id,
       country_region.name country_region_name,
       country_region.slug country_region_slug
FROM facilities
INNER JOIN regions facility_region ON facility_region.source_id = facilities.id
INNER JOIN regions block_region ON block_region.path @> facility_region.path AND block_region.region_type = 'block'
INNER JOIN regions district_region ON district_region.path @> facility_region.path AND district_region.region_type = 'district'
INNER JOIN regions state_region ON state_region.path @> facility_region.path AND state_region.region_type = 'state'
INNER JOIN regions country_region ON country_region.path @> facility_region.path AND country_region.region_type = 'root'
