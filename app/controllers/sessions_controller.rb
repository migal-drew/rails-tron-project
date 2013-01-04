class SessionsController < ApplicationController

	def new
		if signed_in?
			redirect_to user_path(current_user)
		end
		#new 
	end

	def create
	  user = User.find_by_email(params[:session][:email].downcase)
	  if user && user.password == params[:session][:password]
	    # Sign the user in and redirect to the user's show page.
	    sign_in user
	    redirect_to user
	  else
	    # Create an error message and re-render the signin form.
	    flash[:error] = 'Invalid email or password'
      	redirect_to signin_path
	  end
	end

	def destroy
		cookies.delete(:nickname)

		redirect_to signin_path
	end

	def play
		render 'play'
	end
end
