class User < ApplicationRecord
            # Include default devise modules.p
            devise :database_authenticatable, :registerable,
                    :recoverable, :rememberable, :validatable,
                     :omniauthable
            include DeviseTokenAuth::Concerns::User
end
