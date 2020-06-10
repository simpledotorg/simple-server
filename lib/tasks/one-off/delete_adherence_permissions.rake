namespace :permissions do
  desc "Delete view_adherence_follow_up_list permissions"
  task delete_view_adherence_follow_up_list: :environment do
    UserPermission.where(permission_slug: "view_adherence_follow_up_list").destroy_all
  end
end
