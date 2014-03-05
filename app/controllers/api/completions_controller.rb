class Api::CompletionsController < ApplicationController
  before_action :authenticate!

  def create
    @completion = build_completion

    if @completion.save
      notify_completion_creation
      render json: @completion, status: :created
    else
      render json: @completion.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @completion = find_completion

    head :not_found and return unless @completion

    @completion.destroy
    render json: @completion, status: :ok
  end

  private

  def find_completion
    Completion.where(
      completable_id: completion_params[:completable][:id],
      completable_type: completion_params[:completable][:type]
    ).first
  end

  def build_completion
    Completion.new(
      completable_id: completion_params[:completable][:id],
      completable_type: completion_params[:completable][:type],
      user_id: completion_params[:user_id]
    )
  end

  def completion_params
    params.require(:completion).permit(:user_id, completable: [:id, :type])
  end

  def notify_completion_creation
    flow.push_to_team_inbox(
      subject: "Completed #{@completion.completable.class.name}",
      content: @completion.completable.title,
      tags: %w(task completed),
      link: 'https://notdvs.herokuapp.com/#/tasks'
    )
  end
end
