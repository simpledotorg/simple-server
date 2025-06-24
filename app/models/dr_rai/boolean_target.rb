module DrRai
  class BooleanTarget < Target
    def achieved_for?(indicator)
      completed
    end
  end
end
