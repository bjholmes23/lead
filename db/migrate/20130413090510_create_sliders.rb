class CreateSliders < ActiveRecord::Migration
  def change
    create_table :sliders do |t|
      t.string :title
      t.string :body
      t.string :link
      t.string :picture
      t.string :shortbody

      t.timestamps
    end
  end
end
