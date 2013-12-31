require 'bcrypt'

class User < ActiveRecord::Base
	include BCrypt

	attr_accessible :nickname, :email, :password, :password_confirmation
	attr_accessor :password, :password_confirmation

	EMAIL_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
	validates :nickname, :presence => true, 
		:uniqueness => true, :length => { :in => 3..20 }
	validates :email, :presence => true,
		:uniqueness => true, :format => EMAIL_REGEX
	validates :password, :confirmation => true #password_confirmation attr
	validates_length_of :password, :in => 6..20, :on => :create

	before_save { |user| user.email = email.downcase }
	before_save { |user| encrypt_password(user.password) }

  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end

  def password
    @password ||= BCrypt::Password.new(hashed_password)
  end

	def encrypt_password(new_pass)
		@password = BCrypt::Password.create(new_pass)
		self.hashed_password = @password
	end
end
