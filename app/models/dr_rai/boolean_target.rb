module DrRai
  class BooleanTarget < Target
    before_save :stamp_completed_at, if: :completed_changed?

    def achieved_for?(indicator)
      completed
    end

    private

    def stamp_completed_at
      self.completed_at = completed ? Time.current : nil
    end
  end
end
