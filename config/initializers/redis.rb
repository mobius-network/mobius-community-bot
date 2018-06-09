module MobiusBot
  class << self
    def redis
      @redis ||= Redis.new(url: ENV['REDIS_URL'])
    end
  end
end
