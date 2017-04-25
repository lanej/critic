# Critic

Critic inserts an easily verifiable authorization layer into your MVC application using resource policies.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'critic'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install critic

## Usage

### Policies

A policy contains authorization logic for a resource and an authenticated subject.

```ruby
# app/policies/post_policy.rb
class PostPolicy
  include Critic::Policy
end
```

There are two types of methods:

* *action* - determines if subject is authorized to perform a specific operation on the resource
* *scope* - returns a list of resources available to the subject

The default scope is `index` but it can be overridden by specifying `.scope`.

```ruby
# app/policies/post_policy.rb
class PostPolicy
  include Critic::Policy

  # set default scope
  self.scope = :author_index

  # now default scope
  def author_index
    resource.where(author_id: subject.id)
  end

  # no longer the default scope
  def index
    resource.order(:created_at)
  end
end
```

#### Actions

The most basic actions return `true` or `false` to indicate the authorization status.

```ruby
# app/policies/post_policy.rb
class PostPolicy
  include Critic::Policy

  def update?
    !resource.locked? &&
      resource.published_at.present?
  end
end
```

This policy will only allow updates if the post is not `locked`.

Verify authorization using `#authorize`.

```ruby
Post = Struct.new(:locked)
User = Struct.new

PostPolicy.authorize(:update?, User.new, Post.new(false)).granted? #=> true
PostPolicy.authorize(:update?, User.new, Post.new(true)).granted? #=> false
```

#### Authorization Result

Returning a String from your action is interpreted as a failure.  The String is added to the messages of the authorization.

```ruby
Post = Struct.new(:author_id)
User = Struct.new(:id)

class PostPolicy
  include Critic::Policy

  def destroy?
    return true if resource.author_id == subject.id
    "Cannot destroy Post: This post is authored by #{resource.author_id}"
  end
end

authorization = PostPolicy.authorize(destroy?, User.new(1), Post.new(2))
authorization.granted? #=> false
authorization.messages #=> ["Cannot destroy Post: This post is authored by 2"']
```

`halt` can be used to indicate early failure.  The argument provided to `halt` becomes the result of the authorization.

```ruby
Post = Struct.new(:author_id)
User = Struct.new(:id)

class PostPolicy
  include Critic::Policy

  def destroy?
    if resource.author_id != subject.id
      halt "Cannot destroy Post: This post is authored by #{resource.author_id}"
    end
    true
  end
end

authorization = PostPolicy.authorize(destroy?, User.new(1), Post.new(2))
authorization.granted? #=> false
authorization.messages #=> ["Cannot destroy Post: This post is authored by 2"']
```

`halt(true)` indicates immediate success.

```ruby
Post = Struct.new(:author_id)
User = Struct.new(:id)

class PostPolicy
  include Critic::Policy

  def destroy?
    check_ownership
    false
  end

  private

  def check_ownership
    halt(true) if resource.author_id == subject.id
  end
end

authorization = PostPolicy.authorize(destroy?, User.new(1), Post.new(2))
authorization.granted? #=> false
authorization.messages #=> ["Cannot destroy Post: This post is authored by 2"']
```

#### Scopes

Scopes treat `resource` as a starting point and return a restricted set of associated resources.  Policies can have any number of scopes.  The default scope is `#index`.

```ruby
# app/policies/post_policy.rb
class PostPolicy
  include Critic::Policy

  def index
    resource.where(deleted_at: nil, author_id: subject.id)
  end
end
```

Verify authorization using `#authorize`.

```ruby
Post = Class.new(ActiveRecord::Base)
User = Struct.new

authorization = PostPolicy.authorize(index, User.new, Post.new(false))
authorization.granted? #=> true
authorization.result #=> <#ActiveRecord::Relation..>
```

#### Convention

It can be a useful convention to add a `?` suffix to your action methods.  This allows a clear separation between actions and scopes.  All other methods should be `protected`, similar to Rails controller.

```ruby
# app/policies/post_policy.rb
class PostPolicy
  include Critic::Policy

  # default scope
  def index
    resource.where(published: true)
  end

  # custom scope
  def author_index
    resource.where(author_id: subject.id)
  end

  # action
  def show?
    (post.draft? && authored_post?) || post.published?
  end

  protected

  alias post resource

  def authored_post?
    subject == post.author
  end
end
```

### Controller

Controllers are the primary consumer of policies.  Controllers ask the policy if an authenticated subject is authorized to perform a specific action on a specific resource.

#### Actions

In Rails, the policy action is inferred from `params[:action]` which corresponds to the controller action method name.

When `authorize` fails, a `Critic::AuthorizationDenied` exception is raised with reference to the performed authorization.

```ruby
# app/controllers/post_controller.rb
class PostController < ApplicationController
  include Critic::Controller

  rescue_from Critic::AuthorizationDenied do |exception|
    messages = exception.authorization.messages || exception.message
    render json: {errors: [messages]}, status: :unauthorized
  end

  def update
    post = Post.find(params[:id])
    authorize post # calls PostPolicy#update

    render json: post
  end
end
```

When action cannot be inferred, pass the intended action to `authorize`.

```ruby
# app/controllers/post_controller.rb
class PostController < Sinatra::Base
  include Critic::Controller

  error Critic::AuthorizationDenied do |exception|
    messages = exception.authorization.messages || exception.message

    body {errors: [*messages]}
    halt 403
  end

  put '/posts/:id' do |id|
    post = Post.find(id)
    authorize post, :update

    post.to_json
  end
end
```

#### Scopes

Use `authorize_scope` and provide the base scope.  The return value is the result.

```ruby
# app/controllers/post_controller.rb
class PostController < Sinatra::Base
  include Critic::Controller

  get '/customers/:customer_id/posts' do |customer_id|
    posts =
      authorize_scope(Post.where(customer_id: customer_id))

    posts.to_json
  end
end
```

Custom indexes can be used by passing an `action` parameter.

```ruby
# app/controllers/post_controller.rb
class PostController < Sinatra::Base
  include Critic::Controller

  get '/posts' d
    posts =
      authorize_scope(Post, action: :custom_index)

    posts.to_json
  end
end
```

#### Custom subject

By default, the policy's subject is referenced by `current_user`.  Override `critic` to customize.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Critic::Controller

  protected

  def critic
    token
  end
end
```

#### Custom policy

The default policy for a resource is referenced by the resoure class name.  For instance, Critic will look for a `PostPolicy` for a `Post.new` object.  You can set a custom policy for the entire controller by overriding the `policy` method.

```ruby
# app/controllers/post_controller.rb
class PostController < ActionController::Base
  include Critic::Controller

  protected

  def policy(_resource)
    V2::PostPolicy
  end
end
```

You can also provide a specific policy when calling `authorize`

```ruby
# app/controllers/post_controller.rb
class PostController < ActionController::Base
  include Critic::Controller

  def show
    post = Post.find(params[:id])
    authorize post, policy: V2::PostPolicy

    render json: post
  end
end
```


#### Testing

`bundle exec rake spec`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/critic.
