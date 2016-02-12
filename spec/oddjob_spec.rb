require 'spec_helper'

describe OddJob do
  it 'has a version number' do
    expect(OddJob::VERSION).not_to be nil
  end

  it 'has an upload path' do
    expect(OddJob::UPLOAD_PATH).not_to be nil
  end

  it 'has an info path' do
    expect(OddJob::INFO_PATH).not_to be nil
  end

  it 'has a default port that is a a fixnum' do
    expect(OddJob::DEFAULT_PORT).to be_an_instance_of Fixnum
  end
end
