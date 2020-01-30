# Taken from https://github.com/theforeman/puppet-puppet/blob/143199e1f529581f138fcd9c8edea2990ea4a69c/spec/spec_helper.rb
def verify_concat_fragment_exact_contents(subject, title, expected_lines)
  is_expected.to contain_concat__fragment(title)
  content = subject.resource('concat::fragment', title).send(:parameters)[:content]
  expect(content.split(%r{\n}).reject { |line| line =~ %r{(^#|^$|^\s+#)} }).to match_array(expected_lines)
end
