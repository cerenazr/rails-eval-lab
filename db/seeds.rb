# Seed data for N+1 query demonstration
10.times do |i|
  user = User.create!(name: "User #{i + 1}", email: "user#{i + 1}@example.com")
  Profile.create!(user: user, bio: "Bio for #{user.name}", avatar_url: "https://example.com/avatar#{i + 1}.png")

  3.times do |j|
    post = Post.create!(user: user, title: "Post #{j + 1} by #{user.name}", body: "Content...", published: [true, false].sample)

    2.times do |k|
      Comment.create!(post: post, author_name: "Commenter #{k + 1}", body: "Great post!")
    end
  end
end

puts "Seeded #{User.count} users, #{Profile.count} profiles, #{Post.count} posts, #{Comment.count} comments"
