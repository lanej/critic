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


#### Actions

The most basic actions return `true` or `false` to indicate the authorization status.

```ruby
# app/policies/post_policy.rb
class PostPolicy
  include Critic::Policy

  def update?
    !resource.locked
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

#### Convention

It can be a useful convention to add a `?` suffix to your action methods.  This allows a clear separation between actions and scopes.  All other methods should be `protected`, similar to Rails controller.

```ruby
# app/policies/post_policy.rb
class PostPolicy
  include Critic::Policy

  # default scope
  def index
    Post.where(published: true)
  end

  # custom scope
  def author_index
    Post.where(author_id: subject.id)
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

    body {errors: [messages]}
    halt 403
  end

  put '/posts/:id' do |id|
    post = Post.find(id)
    authorize post, :update

    post.to_json
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
