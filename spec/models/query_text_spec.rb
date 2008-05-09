require File.dirname(__FILE__) + '/../spec_helper'

describe QueryText do
  before(:each) do
    @query_text = QueryText.new
  end

  it "should be valid" do
    @query_text.should be_valid
  end
end
