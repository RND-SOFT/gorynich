class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def update
    TestJob.perform_now
    redirect_to root_path
  end
end
