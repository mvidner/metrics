require "active_record"

class Repo < ActiveRecord::Base
  has_many :measurements, inverse_of: :repo
  validates :url,         presence: true, uniqueness: true
end

class Metric < ActiveRecord::Base
  has_many :measurements, inverse_of: :metric
  validates :name,        presence: true, uniqueness: true
end

class Measurement < ActiveRecord::Base
  validates  :date,       presence: true
  belongs_to :repo,       inverse_of: :measurements
  belongs_to :metric,     inverse_of: :measurements
  validates  :value,      presence: true, numericality: true
end
