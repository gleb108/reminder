This is console reminder for expiration dates (domains, certificates etc)
Also it can remind about annual events like birtdays or something.

It's flexible. You can set different notification rules for reminders.

It's friendly. It have color mode for terminals =)

It may be used in ~/.bashrc file (with color mode) or in crontab
to get notification by mail.


------------------------------------------------------------------------------

#CONFIGURATION

File with reminders (default: ~/.reminder) consists of lines
described below. Lines starting with '#' are comments.

Format of reminder line

<DATE> [notification_rule (optional)] <Text of reminder>

DATE should be in human readable format like:

dd.mm.yyyy

dd-mm-yyyy

dd mon yyyy

dd month yyyy

Also you can use magic word EVERY_YEAR instead of yyyy. It's convenient for annual 
events like birtdays or something.


notification rule - thats optional (list of numbers or number diapasons)

default notification rule is [30, 20, 10, 5-0]

which mean to show remind on 30th, 20th, 10th day before this date and every 
day starting from fifth day to day zero
 


------------------------------------------------------------------------------

Example of ~/.reminder

<pre>

#This is comment line and it would be ignored 

######  Another comment line #######

24 Dec 2014 Domain 'call.me' are going to expire soon 
02 Feb EVERY_YEAR Groundhound day

# The reminder bellow is going to be shown during for 5th, 12th, 13th, 14th and 15th Jun 2015

15 Jun [10, 3-0] 2015 Expiration date for SSL certificate by Thawte! 

</pre>

------------------------------------------------------------------------------

#AUTHOR

Gleb Galkin

