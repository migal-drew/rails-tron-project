require 'Redis'

module SessionsHelper

	def sign_in(user)
    	cookies[:nickname] = user.nickname
    	self.current_user = user
      db = Redis.new
      db.select(0)
      player_ht = Hash.new { |hash, key| hash[key] = [] }
      player_ht["id"] = user.id
      player_ht["nickname"] = user.nickname
      player_ht["bike_num"] = -1
      player_ht["room_id"] = -1
      player_ht["score"] = 0
      player_ht["color"] = nil
      player_ht["state"] = "not_ready"
      db.set(user.id, player_ht.to_json)
  	end

  	def sign_out
      cookies.delete(:nickname)
  		@current_user = nil
  	end

  	def current_user
  		@current_user ||= User.find_by_nickname(cookies[:nickname])
  	end

	def current_user=(user)
		@current_user = user
	end


	def signed_in?
		!(self.current_user.nil?)
	end

  def is_admin?(room_ht)
    current_user.id == room_ht["admin_id"]
  end
end
