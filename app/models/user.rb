class User < ActiveRecord::Base
	#include Authentication
  	#include Authentication::ByPassword

	attr_accessible :nickname, :email, :password, 
		:password_confirmation, :wins, :battles, :score

	#attr_accessor :password

	EMAIL_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
	validates :nickname, :presence => true, 
		:uniqueness => true, :length => { :in => 3..20 }
	validates :email, :presence => true,
		:uniqueness => true, :format => EMAIL_REGEX
	validates :password, :confirmation => true #password_confirmation attr
	validates_length_of :password, :in => 6..20, :on => :create

	before_save { |user| user.email = email.downcase }

    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end

end
