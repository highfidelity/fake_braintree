path = File.expand_path("./tmp/braintree_log")
FileUtils.mkdir_p(File.dirname(path))

logger = Logger.new(path)
logger.level = Logger::DEBUG

Braintree::Configuration.logger = logger
