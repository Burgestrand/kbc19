class Child < ApplicationRecord
  validates :score, inclusion: 0..4

  def status
    nil
  end
end