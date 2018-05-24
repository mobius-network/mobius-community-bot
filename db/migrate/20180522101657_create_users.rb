class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.integer :telegram_id
      t.string :username
      t.boolean :is_resident, default: false

      t.timestamps

      t.index :telegram_id, unique: true
      t.index :username, unique: true
    end
  end
end
