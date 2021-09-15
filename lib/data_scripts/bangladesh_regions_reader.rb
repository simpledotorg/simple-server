class BangladeshRegionsReader
  PATH = Rails.root.join("db", "bd_regions.csv")

  def call
    CSV.foreach(path, headers: true).with_index do |row, i|
      p row
      break if i > 5
    end
  end

  def each_row
    converters = lambda {|field, _| field.try(:strip) rescue nil }

    CSV.foreach(PATH, headers: true, header_converters: :symbol, converters: [converters]).with_index do |row, i|
      yield row, i
    end
  end
end
