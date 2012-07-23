# What?

This is the little API consumer that could for the time tracker [Harvest](http://getharvest.com).
All this does is connects to Harvest and finds out how many hours a user has
logged for the current semi-monthly period.

# How?

Enter your credentials into `config/authentication.yml`.  If the file doesn't
exist, just create it first based on `config/authentication.yml.example`. Note
that you must put your `user_id` which you can find inside the querystring
of most Harvest requests when using their website.

Next, run it:

    ruby ticktock.rb

This will output to a file inside the directory called `.hours` with a float
value representing how many hours for that user.

# Automate it!

I have the following in my `~/.bash_profile`:

```bash
parse_hours() {
  [ -e /code/parndt/ticktock/.hours ] && cat /code/parndt/ticktock/.hours
}
set_ps1() {
  # ... Lots of other things here that aren't relevant ...
  
  local hours=`parse_hours`
  PS1="[$hours] \t:"
}

PROMPT_COMMAND += 'set_ps1;'
```

This works in conjunction with a script used by crontab at `~/bin/tick`:

```bash
#!/bin/sh
source /Users/parndt/.rvm/scripts/rvm
cd /path/to/ticktock
ruby ticktock.rb

```

I have this installed to crontab using:

```bash
*/30 * * * * /bin/bash -c '. $HOME/.bashrc && ~/bin/tick'
```

So, every 30 minutes I get an update on my terminal like magic.
This relies on you having run `bundle install` inside your default
Ruby (in my case using rvm) so that all the required gems are available.