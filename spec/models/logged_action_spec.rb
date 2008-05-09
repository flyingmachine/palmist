require File.dirname(__FILE__) + '/../spec_helper'

describe LoggedAction do
  before(:each) do
    @logged_action = LoggedAction.new
  end

  it "should be valid" do
    @logged_action.should be_valid
  end
end
