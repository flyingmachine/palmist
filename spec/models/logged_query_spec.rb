require File.dirname(__FILE__) + '/../spec_helper'

describe LoggedQuery do
  before(:each) do
    @logged_query = LoggedQuery.new
  end

  it "should be valid" do
    @logged_query.should be_valid
  end
end
