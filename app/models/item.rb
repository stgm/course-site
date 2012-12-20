class Item < ActiveRecord::Base
  attr_accessible :category, :position, :reference, :title
end
