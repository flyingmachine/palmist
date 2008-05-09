require File.dirname(__FILE__) + '/../spec_helper'

describe LoggedRequest do
  before(:each) do
    @logged_request = LoggedRequest.new
  end

  it "should be valid" do
    @logged_request.should be_valid
  end
end
