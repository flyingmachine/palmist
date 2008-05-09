# == Schema Information
# Schema version: 1
#
# Table name: logged_actions
#
#  id                   :integer(11)     not null, primary key
#  name                 :string(255)     
#  logged_controller_id :integer(11)     
#

class LoggedAction < ActiveRecord::Base
  belongs_to :logged_controller
end
