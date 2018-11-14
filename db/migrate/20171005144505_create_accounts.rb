class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :email
      t.string :AWSkey
      t.string :skey
      t.string :sellerId
      t.text :price_table
      t.text :trep_table

      t.timestamps
    end
  end
end
