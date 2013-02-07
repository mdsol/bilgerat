bilgerat
========

Bilgerat is a [cucumber](http://cukes.info/) output formatter that sends messages about failing scenarios to [Hipchat](https://www.hipchat.com/) rooms.


usage
-----

In your Gemfile:

```ruby
    gem 'bilgerat',            git: 'git@github.com:mdsol/bilgerat.git'
```

On the command line:

```
cucumber --format Bilgerat --out na --format pretty
```
