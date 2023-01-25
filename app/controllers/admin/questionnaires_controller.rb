class Admin::QuestionnairesController < AdminController
  include Memery

  before_action :is_power_user

  def index
    @questionnaires = Questionnaire.all
  end

  def show
    @questionnaire = Questionnaire.find(params[:id])
  end

  def new
    @questionnaire = Questionnaire.new(
      layout: JSON.pretty_generate(Questionnaire.default_layout.as_json)
    )
  end

  def create
    @questionnaire = Questionnaire.new(create_questionnaire_params)
    @questionnaire.layout = try_parsing_as_json(@questionnaire.layout)
    @questionnaire.save

    if @questionnaire.errors.present?
      @questionnaire.layout = create_questionnaire_params[:layout]
      render :new
    else
      redirect_to admin_questionnaires_url
    end
  end

  def update
    questionnaire = Questionnaire.find(params[:id])
    questionnaire.update(
      is_active: update_questionnaire_params[:is_active]
    )

    if questionnaire.errors.added?(:dsl_version, :taken, value: questionnaire.dsl_version)
      redirect_to admin_questionnaires_url,
        flash: { error: "Questionnaire could not be activated. Only one questionnaire per DSL version and type can be active at a time." }
    else
      redirect_to admin_questionnaires_url, notice: "Questionnaire id #{questionnaire.id} is active."
    end
  end

  def destroy
    @questionnaire = Questionnaire.find(params[:id])
    @questionnaire.discard

    redirect_to admin_questionnaires_url
  end

  def is_power_user
    authorize { current_admin.power_user? }
  end

  memoize def create_questionnaire_params
    params.require(:questionnaire).permit(
      :questionnaire_type,
      :dsl_version,
      :is_active,
      :layout
    )
  end

  def try_parsing_as_json(string)
    JSON.parse(string)
  rescue JSON::ParserError, TypeError => e
    string
  end

  def update_questionnaire_params
    params.require(:questionnaire).permit(
      :is_active
    )
  end
end
