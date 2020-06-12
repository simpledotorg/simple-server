class AdminsController < AdminController
  include Pagination
  include SearchHelper

  before_action :set_admin, only: [:show, :edit, :update, :destroy]
  before_action :verify_params, only: [:update]
  after_action :verify_policy_scoped, only: :index

  def index
    authorize([:manage, :admin, User])
    admins = policy_scope([:manage, :admin, User])

    @admins =
      if searching?
        paginate(admins.search_by_name_or_email(search_query))
      else
        paginate(admins.order("email_authentications.email"))
      end
  end

  def show
  end

  def edit
  end

  def update
    User.transaction do
      @admin.update!(user_params)
      next unless permission_params.present?

      @admin.user_permissions.delete_all
      permission_params.each do |attributes|
        @admin.user_permissions.create!(attributes.permit(
          :permission_slug,
          :resource_id,
          :resource_type
        ))
      end
    end
    render json: {}, status: :ok
  end

  def destroy
    @admin.destroy
    redirect_to admins_url, notice: "Admin was successfully deleted."
  end

  private

  def verify_params
    @admin.assign_attributes(user_params)

    if @admin.invalid?
      render json: {errors: @admin.errors.full_messages},
             status: :bad_request
    end
  end

  def set_admin
    @admin = User.find(params[:id])
    authorize([:manage, :admin, @admin])
  end

  def permission_params
    params[:permissions]
  end

  def user_params
    {full_name: params[:full_name],
     role: params[:role],
     organization_id: params[:organization_id],
     device_updated_at: Time.current}.compact
  end
end
