require 'aruba/cucumber'
require 'fileutils'

Before do
  @aruba_timeout_seconds = 600
  FileUtils.touch "/tmp/test.vmdk"
end

After do
  FileUtils.rm "/tmp/test.vmdk"
end
