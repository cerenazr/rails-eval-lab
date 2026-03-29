# frozen_string_literal: true

class UserDataFetcher
  # Fetches all users with their associated profiles, posts, and comments
  # using eager loading to avoid N+1 query problems.
  #
  # Without eager loading: 1 + N + N + (N*M) queries (e.g., 51 for 10 users)
  # With eager loading:    3 queries total (users+profiles, posts, comments)
  #
  # Usage:
  #   fetcher = UserDataFetcher.new
  #   fetcher.call          # => all users with associations
  #   fetcher.call(limit: 5) # => first 5 users with associations

  def initialize(scope: User.all)
    @scope = scope
  end

  def call(limit: nil)
    users = eager_load_associations
    users = users.limit(limit) if limit
    users.map { |user| serialize(user) }
  end

  private

  attr_reader :scope

  # Uses `includes` to eager load the full association tree in minimal queries:
  #   1. SELECT users + profiles  (eager_load via single JOIN or 2 queries)
  #   2. SELECT posts WHERE user_id IN (...)
  #   3. SELECT comments WHERE post_id IN (...)
  def eager_load_associations
    scope.includes(:profile, posts: :comments)
  end

  def serialize(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      profile: serialize_profile(user.profile),
      posts: user.posts.map { |post| serialize_post(post) }
    }
  end

  def serialize_profile(profile)
    return nil unless profile

    {
      bio: profile.bio,
      avatar_url: profile.avatar_url
    }
  end

  def serialize_post(post)
    {
      id: post.id,
      title: post.title,
      body: post.body,
      published: post.published,
      comments: post.comments.map { |comment| serialize_comment(comment) }
    }
  end

  def serialize_comment(comment)
    {
      id: comment.id,
      author_name: comment.author_name,
      body: comment.body
    }
  end
end
