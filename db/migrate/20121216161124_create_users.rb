class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string  :email
      t.string  :password
      t.string  :nickname
      t.integer :wins
      t.integer :battles
      t.decimal :score

      t.timestamps
    end
  end

  def down
  	drop_table :users
  end
end
