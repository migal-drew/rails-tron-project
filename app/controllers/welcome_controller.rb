class WelcomeController < ApplicationController
  def index
  	@time = Time.now

    unless cookies[:nickname].nil?
  	  unless cookies[:nickname].empty?
  	 	  redirect_to rooms_path
      end
  	end
  end

  def usr_valid_name(name)
    if name.nil? or name.blank? or name.empty?
      return false
    end

    r = Redis.new
    r.select(0)

    if r.nil? 
      return false
    else
      unless r.get(name).nil?
        return false
      end
    end

    return true
  end

  def current_users
    r = Redis.new
    r.select(0)
    ids = r.keys
    @users = []
    ids.each do |i|
      @users.push(i.to_s + " | " + r[i])
    end
  end

  def logout
    name = cookies[:nickname]
    r = Redis.new
    r.del(name)
    cookies[:nickname] = nil
    
  	redirect_to welcome_index_path
  end

end