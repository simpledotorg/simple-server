module PatientImport
  class SpreadsheetTransformer
    attr_reader :data

    def self.transform(data)
      new(data).transform
    end

    def initialize(data)
      @data = data
    end

    def transform
      data
    end
  end
end
