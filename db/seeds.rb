$stderr.puts "Seeding #{Rails.env} database"

Child.create!(name: "Alice")
Child.create!(name: "Bob")
Child.create!(name: "Charlie")
Child.create!(name: "Eve")