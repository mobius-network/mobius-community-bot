RSpec.describe TelegramWebhookController, telegram_bot: :rails do
  describe '#start!' do
    subject { -> { dispatch_message '/start' } }
    it { should respond_with_message 'Hi there!' }
  end
end
