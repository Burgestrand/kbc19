class Child < ApplicationRecord
  validates :score, inclusion: 0..4
end