require File.dirname(__FILE__) + '/../spec_helper'

describe LoggedController do
  before(:each) do
    @logged_controller = LoggedController.new
  end

  it "should be valid" do
    @logged_controller.should be_valid
  end
end
