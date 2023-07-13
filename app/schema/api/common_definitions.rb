class Api::CommonDefinitions
  class << self
    def timestamp
      {type: :string,
       format: "date-time",
       description: "Timestamp with millisecond precision."}
    end

    def month
      {type: :string,
       pattern: '[1-9]{1}[0-9]{1}\-[0-9]{2}'}
    end

    def uuid
      {type: :string,
       format: :uuid,
       pattern: '[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}'}
    end

    def non_empty_string
      {type: :string,
       minLength: 1,
       description: "This string should not be empty."}
    end

    def nullable_timestamp
      timestamp.merge(type: [:string, "null"])
    end

    def bcrypt_password
      {type: :string,
       pattern: '^\$[0-9a-z]{2}\$[0-9]{2}\$[A-Za-z0-9\.\/]{53}$',
       description: "Bcrypt password digest"}
    end

    def array_of(type)
      {type: ["null", :array],
       items: {"$ref" => "#/definitions/#{type}"}}
    end

    def nullable_enum(enum_values)
      {type: [:string, "null"], enum: enum_values << nil}
    end

    def strict_enum(enum_values)
      {type: :string, nullable: false, enum: enum_values}
    end

    def nullable_uuid
      uuid.merge(type: [:string, "null"])
    end
  end
end
