require "rails_helper"

RSpec.describe VoteForBanUser do
  let(:user_to_ban) { Telegram::Bot::Types::User.new(id: 123, username: "john_doe") }
  let(:voter) { Telegram::Bot::Types::User.new(id: 536, username: "charlie") }
  let(:chat_id) { 4256 }

  let(:service_params) do
    {
      chat_id: chat_id,
      user_to_ban_id: user_to_ban.id,
      voter: voter,
      vote: vote,
    }
  end
  describe ".call" do
    context "when user votes for the ban" do
      let(:vote) { :for }

      context "when there are not sufficient votes yet" do
        it "returns :continue result" do
          ctx = described_class.call(**service_params)

          expect(ctx.result.resolution).to eq(:continue)
        end
      end

      context "when there are sufficient votes to ban user" do
        before do
          (described_class.ban_votes_threshold - 1).times do |i|
            described_class.call(
              chat_id: chat_id,
              user_to_ban_id: user_to_ban.id,
              voter: Telegram::Bot::Types::User.new(id: 500 + i),
              vote: :for,
            )
          end

          allow(Telegram.bot).to \
            receive(:restrict_chat_member)
            .with(hash_including(chat_id: chat_id, user_id: user_to_ban.id))
            .and_return(true)
        end

        it "bans user" do
          ctx = described_class.call(**service_params)

          expect(Telegram.bot).to \
            have_received(:restrict_chat_member)
            .with(
              chat_id: chat_id,
              user_id: user_to_ban.id,
              can_send_messages: false,
              can_send_media_messages: false,
              can_send_other_messages: false,
            )
          expect(ctx.result.resolution).to eq(:banned)
        end
      end
    end

    context "when user votes against the ban" do
      let(:vote) { :against }

      context "when there are not sufficient votes yet" do
        it "returns :continue result" do
          ctx = described_class.call(**service_params)

          expect(ctx.result.resolution).to eq(:continue)
        end
      end

      context "when there are sufficient votes" do
        before do
          (described_class.save_votes_threshold - 1).times do |i|
            described_class.call(
              chat_id: chat_id,
              user_to_ban_id: user_to_ban.id,
              voter: Telegram::Bot::Types::User.new(id: 500 + i),
              vote: :against,
            )
          end
        end

        it "saves user" do
          ctx = described_class.call(**service_params)

          expect(ctx.result.resolution).to eq(:saved)
        end
      end
    end

  end
end
