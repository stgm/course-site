class Schedule < ActiveRecord::Base

	has_many :schedule_spans, dependent: :destroy

end
