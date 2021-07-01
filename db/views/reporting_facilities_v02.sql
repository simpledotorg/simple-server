SELECT
    facilities.id AS facility_id,
    facilities.name AS facility_name,
    facilities.facility_type as facility_type,
    facilities.facility_size as facility_size,
    facility_regions.id AS facility_region_id,
    facility_regions.name AS facility_region_name,
    facility_regions.slug AS facility_region_slug,
    block_regions.id AS block_region_id,
    block_regions.name AS block_name,
    block_regions.slug AS block_slug,
    district_regions.source_id AS district_id,
    district_regions.id AS district_region_id,
    district_regions.name AS district_name,
    district_regions.slug AS district_slug,
    state_regions.id AS state_region_id,
    state_regions.name AS state_name,
    state_regions.slug AS state_slug,
    org_regions.source_id AS organization_id,
    org_regions.id AS organization_region_id,
    org_regions.name AS organization_name,
    org_regions.slug AS organization_slug
FROM regions AS facility_regions
         INNER JOIN facilities ON facilities.id = facility_regions.source_id
         INNER JOIN regions AS block_regions ON block_regions.path = subpath(facility_regions.path,0,-1)
         INNER JOIN regions AS district_regions ON district_regions.path = subpath(block_regions.path,0,-1)
         INNER JOIN regions AS state_regions ON state_regions.path = subpath(district_regions.path,0,-1)
         INNER JOIN regions AS org_regions ON org_regions.path = subpath(state_regions.path,0,-1)
WHERE facility_regions.region_type = 'facility'
