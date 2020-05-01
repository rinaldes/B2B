class GroupNotification < ActiveRecord::Base
  attr_accessible :receipant_id
  belongs_to :notification
  belongs_to :user, foreign_key: :receipant_id
  attr_accessible :state

  state_machine initial: :unread do
    state :unread, value: nil
    state :read, value: 1

    event :read do
      transition :unread => :read
    end
  end
end
