require "rails_helper"

RSpec.describe VoteForBanUser do
  let(:user_to_ban) { "john_doe" }
  let(:voter) { "charlie" }
  let(:chat_id) { 4256 }

  let(:service_params) do
    {
      chat_id: chat_id,
      user_to_ban: user_to_ban,
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

          expect(ctx.result).to eq(:continue)
        end
      end

      context "when there are sufficient votes to ban user" do
        before do
          (described_class::BAN_THRESHOLD - 1).times do |i|
            described_class.call(chat_id: chat_id, user_to_ban: user_to_ban, voter: "#{voter}_#{i}", vote: :for)
          end

          allow(Telegram.bot).to \
            receive(:kick_chat_member)
            .with(chat_id: chat_id, user_id: user_to_ban)
            .and_return(true)
        end

        it "bans user" do
          ctx = described_class.call(**service_params)

          expect(Telegram.bot).to \
            have_received(:kick_chat_member)
            .with(chat_id: chat_id, user_id: user_to_ban)
          expect(ctx.result).to eq(:banned)
        end
      end
    end

    context "when user votes against the ban" do
      let(:vote) { :against }

      context "when there are not sufficient votes yet" do
        it "returns :continue result" do
          ctx = described_class.call(**service_params)

          expect(ctx.result).to eq(:continue)
        end
      end

      context "when there are sufficient votes" do
        before do
          (described_class::SAVE_THRESHOLD - 1).times do |i|
            described_class.call(chat_id: chat_id, user_to_ban: user_to_ban, voter: "#{voter}_#{i}", vote: :against)
          end
        end

        it "saves user" do
          ctx = described_class.call(**service_params)

          expect(ctx.result).to eq(:saved)
        end
      end
    end

  end
end
