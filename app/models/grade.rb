class Grade < ActiveRecord::Base

	belongs_to :submit

	attr_accessible :comments, :correctness, :design, :grade, :grader, :scope, :style

end
