require 'bcrypt'

class UsersController < ApplicationController

  include BCrypt

  # GET /users
  # GET /users.json
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    if signed_in?
      redirect_to user_path(current_user)
    else
      @user = User.new

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @user }
      end
    end
  end

  # GET /users/1/edit
  def edit
    #@user = User.find(params[:id])
    redirect_to current_user
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])
    #@user.nickname = params[:user][:nickname]
    #@user.email = params[:user][:email]
    #@user.password = params[:user][:password]
    @user.wins = 0
    @user.battles = 0
    @user.score = 0

    if @user.save
      redirect_to signin_path,
        notice: 'You have been successfully signed up! Please sign in!'
    else
      render action: "new"
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy
  end
end
