require 'Redis'

module SessionsHelper

	def sign_in(user)
    	cookies[:nickname] = user.nickname
    	self.current_user = user
      db = Redis.new
      
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
end
