class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, through: :posts
  has_many :run_logs, dependent: :destroy
end
