# Find Braintree spec/ dir
braintree_spec_dir = nil
$LOAD_PATH.detect do |dir|
  if File.exists?(File.join(dir, "braintree.rb"))
    braintree_spec_dir = File.expand_path(File.join(dir,"..","spec"))
    $LOAD_PATH.unshift(braintree_spec_dir)
  end
end

# Used by braintree spec_helper
ENV["LIBXML_VERSION"] = Gem.loaded_specs['libxml-ruby'].version.to_s
ENV["BUILDER_VERSION"] = Gem.loaded_specs['builder'].version.to_s

require File.join(braintree_spec_dir, 'integration', 'spec_helper')

Dir[File.join(braintree_spec_dir, 'integration', '**', '*_spec.rb')].each do |f|
  require File.expand_path(f)
end
