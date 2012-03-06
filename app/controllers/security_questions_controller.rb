class SecurityQuestionsController < ApplicationController
  before_filter :authenticate_user!

  layout "admin"

  def index
    @default_questions =  DefaultQuestion.get_default_questions
  end

  def edit
    @question = DefaultQuestion.find(params[:id])
  end

  def update
    @question = DefaultQuestion.find(params[:id])
    if @question.update_attributes(params[:default_question])
      flash[:notice] = "Question updated successfully"
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end
  
end
