# Chemistry
A simple, lightweight single-site CMS that you can bolt onto any Rails applicaiton to give it a home page, some other pages and a nice toolkit for editing and linking them. It is meant to be just complicated enough: `pages` are built out of a stack of pre-styled `sections` ordered by a `template`. Your designer prepares the templates and CSS. Your authors populate the sections, adding images and video as required.

Chemistry is essentially an API and comes with a nice editing SPA, but of course you can add any interface you like.


## Requirements
We make some assumptions about your application:

* It has users of some kind
* It uses cancan(can) to authorize its users
* User model responds to can?

For that last you may need to do some delegating to Ability in the User class:

```
  def ability
    @ability ||= Ability.new(self)
  end
  delegate :can?, :cannot?, to: :ability
```

Chemistry requires Rails 5.1+ and uses Paperclip for asset-attachment, which your application will need to configure.


## Usage

...



## Installation
Add this line to your application's Gemfile:

```ruby
gem 'chemistry'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install chemistry
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
