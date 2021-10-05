module LogFriend
  module Extensions
    REGEXP = /^\s*d\s*\(?(.*)\)?\s*$/

    def d(msg)
      location = caller_locations(1..1).first
      path = location.absolute_path
      line = Pathname(path).readlines[location.lineno - 1]

      arg_name = if match = line.match(REGEXP)
        match[1]
      else
        "error finding arg name"
      end
      pp [arg_name, msg]
    end
  end
end
