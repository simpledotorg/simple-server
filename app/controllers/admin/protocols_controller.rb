# frozen_string_literal: true

class Admin::ProtocolsController < AdminController
  before_action :set_protocol, only: [:show, :edit, :update, :destroy]

  def index
    authorize { current_admin.accessible_organizations(:manage).any? }
    @protocols = current_admin.accessible_protocols(:manage).order(:name)
  end

  def show
    @protocol_drugs = @protocol.protocol_drugs
  end

  def new
    authorize { current_admin.accessible_organizations(:manage).any? }
    @protocol = Protocol.new
  end

  def edit
  end

  def create
    authorize { current_admin.accessible_organizations(:manage).any? }
    @protocol = Protocol.new(protocol_params)

    if @protocol.save
      redirect_to [:admin, @protocol], notice: "Medication list was successfully created"
    else
      render :new
    end
  end

  def update
    if @protocol.update(protocol_params)
      redirect_to [:admin, @protocol], notice: "Medication list was successfully updated"
    else
      render :edit
    end
  end

  def destroy
    @protocol.destroy
    redirect_to admin_protocols_url, notice: "Medication list was successfully deleted"
  end

  private

  def set_protocol
    @protocol = authorize { current_admin.accessible_protocols(:manage).find(params[:id]) }
  end

  def protocol_params
    params.require(:protocol).permit(:name, :follow_up_days)
  end
end
