class Admin::QuestionnairesController < AdminController
  before_action :is_power_user

  def index
    @questionnaires = Questionnaire.all
  end

  def new
  end

  def create
  end

  def update
    binding.pry
  end

  def destroy
  end

  def is_power_user
    authorize { current_admin.power_user? }
  end
end
