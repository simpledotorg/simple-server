module DrRai
  # Query Factory
  #
  # When creating SQL-backed indicators, these indicators come with their own
  # queries. The query factory tells the query necessary for certain
  # indicators. By default, it vends one query for inserting, and another for
  # updating. The primary client for this is the DrRai::DataService which uses
  # this to populate the data in the tables.
  class QueryFactory
    attr_reader :from_date, :to_date

    class << self
      def for klazz, from: nil, to: nil
        raise unless klazz < ApplicationRecord

        instance = nil

        if klazz <= Data::Titration
          instance = DrRai::TitrationQueryFactory.new(from, to)
        elsif klazz <= Data::Statin
          instance = DrRai::StatinsQueryFactory.new(from, to)
        else
          raise "Unsupported"
        end

        instance
      end
    end

    def initialize from, to
      @from = from
      @to = to

      set_date_boundaries!
    end

    def inserter
      # Format should be
      #   insert into <tbl> ([...columns]) [..query]
      raise "Unimplemented"
    end

    def updater
      # Format should be
      #   merge into <tbl> as t
      #   using [...query]
      #   on month_date
      #   when not matched and [column compare - insert clause] then
      #     insert values ([select values])
      #   when matched and [column compare - update clause] then
      #     update set [col = old_col <op> new_col];
      # see https://www.postgresql.org/docs/current/sql-merge.html#id-1.9.3.156.9
      raise "Unimplemented"
    end

    def months_between
      (@to_date.year * 12 + @to_date.month) - (@from_date.year * 12 + @from_date.month)
    end

    private

    def set_date_boundaries!
      @from_date = if @from.nil?
        1.year.ago.to_date
      else
        @from
      end

      @to_date = if @to.nil?
        Date.today
      else
        @to
      end
    end
  end
end
