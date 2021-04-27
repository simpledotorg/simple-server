Time::DATE_FORMATS[:mon_year] = "%b-%Y"
Date::DATE_FORMATS[:mon_year] = "%b-%Y"

Date::DATE_FORMATS[:mon_year_multiline] = lambda { |date| date.strftime("%b-%Y").tr("-", "\n") }
Time::DATE_FORMATS[:mon_year_multiline] = lambda { |date| date.strftime("%b-%Y").tr("-", "\n") }

Time::DATE_FORMATS[:month_year] = "%B %Y"
Date::DATE_FORMATS[:month_year] = "%B %Y"

Time::DATE_FORMATS[:day_mon_year] = "%-d-%b-%Y"
Date::DATE_FORMATS[:day_mon_year] = "%-d-%b-%Y"
