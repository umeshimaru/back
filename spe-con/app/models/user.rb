class User < ApplicationRecord
        
            # Include default devise modules.p
            devise :database_authenticatable, :registerable,
                    :recoverable, :rememberable, :trackable, :validatable,
                     :omniauthable
            include DeviseTokenAuth::Concerns::User

 

            
end
