class VotesStorage
  VOTE_FOR = :for
  VOTE_AGAINST = :against

  class InvalidVoteError < StandardError; end

  def initialize(user_to_ban)
    @user_to_ban = user_to_ban
  end

  def store_vote(voter, vote)
    raise InvalidVoteError unless vote.to_sym.in?([VOTE_FOR, VOTE_AGAINST])
    redis.sadd(key(vote), voter)
  end

  def voted?(voter)
    redis.sismember(key(VOTE_FOR), voter) ||
      redis.sismember(key(VOTE_AGAINST), voter)
  end

  def fetch_voters
    [redis.smembers(key(VOTE_FOR)), redis.smembers(key(VOTE_AGAINST))]
  end

  def clear
    redis.del(key(VOTE_FOR))
    redis.del(key(VOTE_AGAINST))
  end

  private

  def redis
    @redis = MobiusBot.redis
  end

  def key(vote)
    "ban_voters:#{vote}:#{@user_to_ban}"
  end
end
