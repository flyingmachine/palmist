# == Schema Information
# Schema version: 1
#
# Table name: logged_controllers
#
#  id   :integer(11)     not null, primary key
#  name :string(255)     
#

class LoggedController < ActiveRecord::Base
  has_many :logged_actions, :order => "name"
end
