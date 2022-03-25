DEFAULT_PERIOD_FORMAT = "%b-%Y".freeze
Time::DATE_FORMATS[:mon_year] = DEFAULT_PERIOD_FORMAT
Date::DATE_FORMATS[:mon_year] = DEFAULT_PERIOD_FORMAT
Time::DATE_FORMATS[:default_period] = DEFAULT_PERIOD_FORMAT
Date::DATE_FORMATS[:default_period] = DEFAULT_PERIOD_FORMAT

Date::DATE_FORMATS[:mon_year_multiline] = "%b\n%Y"
Time::DATE_FORMATS[:mon_year_multiline] = "%b\n%Y"

Time::DATE_FORMATS[:month_year] = "%B %Y"
Date::DATE_FORMATS[:month_year] = "%B %Y"

Time::DATE_FORMATS[:month_name] = "%B"
Date::DATE_FORMATS[:month_name] = "%B"

Time::DATE_FORMATS[:cohort] = lambda { |value| "#{value.prev_month.strftime("%b")}/#{value.strftime("%b")}" }
Date::DATE_FORMATS[:cohort] = lambda { |value| "#{value.prev_month.strftime("%b")}/#{value.strftime("%b")}" }

Time::DATE_FORMATS[:day_mon_year] = "%-d-%b-%Y"
Date::DATE_FORMATS[:day_mon_year] = "%-d-%b-%Y"

Time::DATE_FORMATS[:day_mon_year_time] = "%d-%^b-%Y %I:%M%p"

# DHIS2 has its own period string formats
# https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-master/introduction.html#webapi_date_perid_format
Time::DATE_FORMATS[:dhis2] = "%Y%m"
Date::DATE_FORMATS[:dhis2] = "%Y%m"
