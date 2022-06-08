class ChangeUserIdsToBigint < ActiveRecord::Migration[5.2]
  def change
    change_column :users, :id, :bigint
    change_column :users, :telegram_id, :bigint
  end
end
