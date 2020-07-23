class Upcoming::ReadPolicy < Struct.new(:user, :read)
  def aggregates?
    user.super_admin? || user.accesses.exists?
  end

  def identifiable_info?
    user.super_admin? || user.accesses.admin.exists?
  end
end
