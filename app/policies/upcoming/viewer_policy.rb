class Upcoming::ViewerPolicy < Struct.new(:user, :viewer)
  def aggregates?
    user.accesses.exists?
  end

  def identifiable_info?
    user.accesses.admin.exists?
  end
end
