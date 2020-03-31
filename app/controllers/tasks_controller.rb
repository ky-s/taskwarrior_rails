class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy, :done]

  # GET /tasks
  def index
    @tasks = Task.all
    @new_task = Task.new
    @show_done = false
  end

  # GET /tasks/1/edit
  def edit
  end

  # POST /tasks
  def create
    @task = Task.new(task_params)

    @task.save
  end

  # PATCH/PUT /tasks/1
  def update
    @task.update(task_params)
  end

  # DELETE /tasks/1
  def destroy
    @task.destroy
  end

  def done
    @task.done!
  end

  def redue
    Task.all.reject(&:done?).select(&:deadline?).each do |task|
      task.update('due' => Date.today)
    end

    redirect_to action: :index
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = Task.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def task_params
      params.require(:task)
        .permit(:description, :due, :project, :priority, :tags)
        .tap { |p| p[:due] = p[:due].to_date }
    end
end
