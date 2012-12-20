class Page < ActiveRecord::Base
  attr_accessible :content, :position, :section, :title
end
