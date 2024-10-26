module Plugins
  module Exam
    class Exam < ApplicationRecord

      belongs_to :pset
      delegate :name, to: :pset

      serialize :config, Hash

    end
  end
end
