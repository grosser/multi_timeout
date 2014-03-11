require "spec_helper"

describe MultiTimeout do
  it "has a VERSION" do
    MultiTimeout::VERSION.should =~ /^[\.\da-z]+$/
  end
end
