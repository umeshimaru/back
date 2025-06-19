class CreateGrammars < ActiveRecord::Migration[8.0]
  def change
    create_table :grammars do |t|
      t.string :name

      t.timestamps
    end
  end
end
