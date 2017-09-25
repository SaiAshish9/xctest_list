class XCTestList
  def self.validate_bundle(xctest_bundle_path)
    raise "Cannot find xctest bundle at path '#{xctest_bundle_path}'" unless Dir.exist?(xctest_bundle_path)

    is_xctest_bundle = File.extname(xctest_bundle_path) == '.xctest'
    raise "Invalid xctest bundle given: '#{xctest_bundle_path}'" unless is_xctest_bundle
  end

  def self.binary_path(xctest_bundle_path)
    validate_bundle(xctest_bundle_path)

    xctest_binary_name = File.basename(xctest_bundle_path, '.*')
    xctest_binary_path = File.join(xctest_bundle_path, xctest_binary_name)
    unless File.exist?(xctest_binary_path)
      raise "Missing xctest binary: '#{xctest_binary_path}'"
    end
    xctest_binary_path
  end

  def self.objc_tests(xctest_bundle_path)
    objc_symbols_cmd = 'nm -U '
    objc_symbols_cmd << "'#{binary_path(xctest_bundle_path)}'"

    tests = []
    `#{objc_symbols_cmd}`.each_line do |line|
      if / t -\[(?<testclass>\w+) (?<testmethod>test\w+)\]/ =~ line
        tests << "#{testclass}/#{testmethod}"
      end
    end
    tests
  end

  def self.swift_symbols(swift_symbols_cmd_output)
    swift_symbols_cmd_output.gsub(/^.* .* (.*)$/, '\1')
  end

  def self.swift_tests(xctest_bundle_path)
    swift_symbols_cmd_output = `nm -gU '#{binary_path(xctest_bundle_path)}'`
    tests = []
    swift_symbols(swift_symbols_cmd_output).each_line do |symbol|
      if /\w+\.(?<testclass>[^\.]+)\.(?<testmethod>test[^\(]+)/ =~ `xcrun swift-demangle #{symbol}`
        tests << "#{testclass}/#{testmethod}"
      end
    end
    tests
  end

  def self.tests(xctest_bundle_path)
    objc_tests(xctest_bundle_path) | swift_tests(xctest_bundle_path)
  end
end
