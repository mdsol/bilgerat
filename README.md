bilgerat
========

Bilgerat is a [cucumber](http://cukes.info/) output formatter that sends messages about failing scenarios to [HipChat](https://www.hipchat.com/) rooms.


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


configuration
-----
You must supply a configuration file that contains credentials to use the HipChat API.  By default Bilgerat looks for this file is config/hipchat.yml.  You can override this location by setting the HIPCHAT_CONFIG_PATH environment variable.

The configuration file contains settings per context.  You should set all configuration items in the default context.  You can override these settings for other contexts.  Use the BILGERAT_CONTEXT environment variable to choose the context.

For example our CI server runs cucumber scenarios in parallel for the first round, then reruns failing scenarios in the final round.  Our config file looks like this:

```
default:
  user: 'Bilge Rat #{TEST_ENV_NUMBER}'
  auth_token: 'goes here'
  room: 'test room'
  error_color: 'red'
first_round:
  error_color: 'purple'
final_round:
  user: 'Final Bilge Rat'
```

