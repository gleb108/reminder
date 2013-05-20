#!/usr/bin/perl 

use Time::localtime;
use Date::Calc qw(Delta_Days Decode_Month Month_to_Text This_Year check_date);
use Getopt::Long;
use strict;

Getopt::Long::Configure ("bundling");

=head1 NAME

This is console reminder for expiration dates or annual events


=head1 SYNOPSIS

reminder [OPTIONS] 

Options:
 -f <file>, --file=<file> file with dates (default: ~/.reminder)
   -a, --all  show all reminders (ignore notification rules)
   -c, --color  use ANSI colors 
   -v, --verbose  verbose mode 
   
   -h, --help  show this text 

=head1 DESCRIPTION

B<reminder> is console reminder which shows warning for dates with defined rules.
It may be used in ~/.bashrc file (with color mode) or in crontab
to get notification by mail.

=head1 OPTIONS

=over 4

=item B<-f> I<file> or B<--file=>I<file>

Use alternative remind list instead of ~/.reminder

=item B<-a> or B<--all>

Show all future reminders from list (ignore notification rules) 

=item B<-c> or B<--color>

Use ANSI colors 

=item B<-v> or B<--verbose>

Verbose mode for debug

=item B<-h> or B<--help>

Show help  

=back


=head1 CONFIGURATION

File with reminders (default: ~/.reminder) consists of lines
described below. Lines starting with '#' are comments.



=head2 Format of reminder line

B<date [notification_rule] Description>

=over 4

=item B<date> 

date in human readable format like:

dd.mm.yyyy

dd-mm-yyyy

dd mon yyyy

dd month yyyy

Also you can use magic word EVERY_YEAR instead of yyyy. It's convenient for annual 
events like birtdays or something.

=item B<notification rule> (list of numbers or number diapasons)

notification rule - (optional) default notification rule is [30, 20, 10, 5-0]

which mean to show remind on 30th, 20th, 10th day before this date and every 
day starting from fifth day to day zero
 
=item B<description> (string)

Text of reminder

=back

=head2 Example of ~/.reminder


24 Dec 2014 Domain 'call.me' are going to expire soon 

02 Feb EVERY_YEAR Groundhound day


# The reminder bellow is going to be shown during for 5th, 12th, 13th, 14th and 15th Jun 2015

15 Jun [10, 3-0] 2015 Expiration date for SSL certificate by Thawte! 

=cut

=head1 AUTHOR

Gleb Galkin 

=cut

######################################################################


my %colorize = (
    3  => "red",
	10 => "blue",
	30 => "green"
);

# default notification rules
my $notification_rule_def = "[30, 20, 10, 5-0]";

my ($color, $today, $c_day, $c_mon, $c_year, $e_mon, $e_day, $e_year, $delta, $string, $out);

$today = localtime(time);
($c_day, $c_mon, $c_year)  = ($today->mday, $today->mon+1, $today->year + 1900);



my $opt_file = $ENV{'HOME'} . "/.reminder";
my $opt_all='';
my $opt_color='';
my $opt_v='';
my $opt_help='';

usage() unless GetOptions(
     "file|f=s"            => \$opt_file,
     "all|a"               => \$opt_all,
     "color|c"             => \$opt_color,
     "verbose|v"           => \$opt_v,
     "help|h|?"            => \$opt_help
);

usage() if $opt_help;


$opt_v && print "\n$0:\n-- verbose mode ON\n\n";
$opt_v && print "read file $opt_file\n";

open FILE, $opt_file || die "Can't open file $opt_file\n$!\n";

output ("\nreminders for $c_day-" . Month_to_Text($c_mon) . "-$c_year\n\n", "white");

my $i=0;
my $events=0;
while (<FILE>) {
   chomp; 
   $i++;
   undef($color);
   undef($string);
   $opt_v && print "$i: $_\n";
   m/^\s*#|^$/ && next;

   if (/^\s*\d{1,2}\.\w+\.\d{4}\s+/) {
	  s/\./ /;
	  s/\./ /;
   }	   
   elsif (/^\s*\d{1,2}-\w+-\d{4}\s+/) {
	  s/-/ /;
	  s/-/ /;
   }	   
   quit ("$opt_file: string number $i is invalid\n> $_ <\n")
        unless (/^(\d+)\s+(\w+)\s+(\d{4}|EVERY_YEAR)\s+(\[.*\])?\s*(.*)$/);
   $string = "$1 $2 $3 - $5"; 
   my $notification_rule = $4 ? $4 : $notification_rule_def;

   $e_day = $1;
   my ($tmp2, $tmp3, $tmp4, $tmp5) = ($2, $3, $4, $5);

   quit ("$opt_file: string number $i contain invalid data\n> $_<\n        ^^^^^^\n") 
      unless ($tmp3);
   if ($tmp3 eq 'EVERY_YEAR') {
	  $e_year = This_Year; 
   }	   
   else { $e_year=$tmp3 }

   quit ("$opt_file: string number $i contain invalid show days list\n> $tmp4 <\n") 
      if ($tmp4 && $tmp4 !~ /^\[[0-9, -]+\]$/);

   if ($tmp2 =~ /\D/) {
	  quit ("$opt_file: string number $i contain invalid month\n> $_<\n     ^^^\n") 
	    unless ($e_mon = Decode_Month($tmp2));  
   }
   elsif ($tmp2 <= 12) {
      $e_mon = $tmp2;
   }	   

   quit ("$opt_file: string number $i contain invalid month\n> $_<\n     ^^^\n")
        unless ($e_mon);

   quit ("$opt_file: string number $i contain invalid data\n> $_<\n  ^^^^^^\n") 
      unless (check_date($e_year, $e_mon, $e_day));



   $delta = Delta_Days($c_year, $c_mon, $c_day, $e_year, $e_mon, $e_day);
   print "delta=$delta\n" if $opt_v;   
   my $check = check_show_day($delta, $notification_rule); 
   quit ("$opt_file: string number $i contain invalid show days list\n> $notification_rule <\n") 
    if ($check == -1);
   if ($check) {
      undef($color);
      foreach (reverse sort by_number keys %colorize) { 
	     if ($delta <= $_ && $delta > 0) { $color = $colorize{$_} }
	  } 
      if ($check==1) {
	     output ("$string (in $delta days)\n", $color);
		 $events++;
	  }	 
   }
}

print $out if ($events);


sub usage {
   print "
Usage: $0 [OPTIONS] 

Options:
   -f <file>, --file=<file> file with reminders (default: ~/.reminder)
   -a, --all  show all events (ignore notification rules)
   -c, --color  use ANSI colors 
   -v, --verbose  verbose mode 
   
   -h, --help  show this text 
   
\n";
   exit;
}


sub output {
   my ($string, $color) = @_;
   my %colors = (white => "\033[1;37m", red => "\033[1;31m", blue => "\033[1;34m", green => "\033[1;32m");
   my $color_off ="\033[0m"; 
 
   $out .= $colors{$color} if $opt_color;
   $out .= $string;
   $out .= $color_off if $opt_color;

}

sub quit {
  print $_[0];
  exit;
}

sub check_show_day {
  my ($delta, $days) = @_;
  return 1 if ($opt_all);
  if ($delta < 0) { 
     return 1 unless $delta%10;
  }
  $days =~ s/[\[\] ]//g;
  my @array = split(/,/, $days);
  my ($from, $to);
  foreach (@array) {
     if (/(^\d+)-(\d+)$/) {
	    if ($1 > $2) { 
		   $from=$2;
		   $to=$1;
		}
		else {
		   $from=$1;
		   $to=$2;
		}
		return 1 if ($delta >= $from && $delta <= $to);
	 }
	 elsif (/^\d+$/) {
	    return 1 if ($delta==$_);
	 }
	 else {return -1}
  }
  return 0;
}

sub by_number { $a <=> $b }
