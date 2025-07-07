module DrRai
  class NumericTarget < Target
    validates :numeric_value, presence: true
    def achieved_for?(indicator)
      raise "Unimplemented"
    end
  end
end
