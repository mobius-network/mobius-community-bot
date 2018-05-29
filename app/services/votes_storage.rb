class VotesStorage
  VOTE_FOR = :for
  VOTE_AGAINST = :against

  class InvalidVoteError < StandardError; end

  def initialize(user_to_ban_id)
    @user_to_ban_id = user_to_ban_id
  end

  def store_vote(voter, vote)
    raise InvalidVoteError unless vote.to_sym.in?([VOTE_FOR, VOTE_AGAINST])
    redis.sadd(key(vote), voter)
  end

  def voted?(voter)
    redis.sismember(key_for, voter) || redis.sismember(key_against, voter)
  end

  def fetch_voters
    [redis.smembers(key_for), redis.smembers(key_against)]
  end

  def clear
    redis.del(key_for)
    redis.del(key_against)
  end

  def voting_is_ongoing?
    redis.exists(key_for) || redis.exists(key_against)
  end

  private

  def redis
    @redis = MobiusBot.redis
  end

  def key_for
    key(VOTE_FOR)
  end

  def key_against
    key(VOTE_AGAINST)
  end

  def key(vote)
    "ban_voters:#{vote}:#{@user_to_ban_id}"
  end
end
