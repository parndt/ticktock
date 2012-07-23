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

I set up a crontab task to poll this ruby file every 30 minutes so that I had
the current value and then I added it to my `~/.bash_profile` PS1.