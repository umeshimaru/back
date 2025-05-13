
  module Auth
    class RegistrationsController < DeviseTokenAuth::RegistrationsController
      private
  
      def sign_up_params
        params.permit(:name, :password, :password_confirmation)
      end
  
    
    end
  end

