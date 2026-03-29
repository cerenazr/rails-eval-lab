require 'faker'

puts "Biraz zaman alabilir, #{200} kullanıcı ve ilişkileri (profile, post, comment) oluşturuluyor..."
200.times do
  user = User.create!(
    name: Faker::Name.name,
    email: Faker::Internet.unique.email,
    active: [true, false].sample
  )
  
  Profile.create!(
    user: user, 
    bio: Faker::Lorem.paragraph, 
    avatar_url: Faker::Avatar.image
  )

  rand(5..15).times do
    post = user.posts.create!(
      title: Faker::Lorem.sentence,
      body: Faker::Lorem.paragraphs(number: 2).join("\n\n"),
      published: [true, false].sample
    )
    
    rand(1..3).times do
      post.comments.create!(
        author_name: Faker::Name.name,
        body: Faker::Lorem.sentence
      )
    end
  end
end

puts "Seeded #{User.count} users, #{Profile.count} profiles, #{Post.count} posts, #{Comment.count} comments"

Challenge.create!(
  slug: "n_plus_one_dashboard",
  title: "Dashboard N+1 Katliamı",
  description: "Kullanıcı dashboard'u binlerce SQL sorgusu çalıştırıyor. Düzelt.",
  baseline_queries: 1051,
  baseline_time_ms: 1150.00,
  credit_cost: 5
)
puts "Seeded 1 Challenge (baseline: 1051 queries, 1150ms)."
