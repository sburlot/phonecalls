#!/usr/bin/perl

# this script will:
#
# - Parse the swisscom website and get all answered and missed calls
# - Save these calls to the database
# - Post a notification if there's a new missed call


use strict;
use warnings;

use HTTP::Cookies;
use HTTP::Request::Common qw(POST GET);
use LWP::UserAgent;
use Data::Dumper;
use Mojo::DOM;
use feature 'say';
use DBI;
use DateTime::Format::Strptime qw (strptime);
use URI::Escape;
use FindBin;
use File::Spec;

use constant PROWL_API_KEY => 'thisisthekey';

sub send_notification ($$);

###########################################
my $database = "swisscom" ;
my $db_user = "batman" ;
my $dp_pwd = "nanananana" ;

my $swisscom_login = 'KarateSwag22';
my $swisscom_pwd = 'mission404';

## NO USER SERVICEABLE PARTS BELOW
###########################################

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

my $cj = HTTP::Cookies->new(file => 'cookieslwp', autosave => 1, ignore_discard => 1);
my $ua = LWP::UserAgent->new;
$ua->cookie_jar($cj);

$ua->default_header('Content-Type' => 'text/plain;charset=UTF-8');

my $dbh = DBI->connect('DBI:mysql:' . $database, $db_user, $dp_pwd
	           ) || die "Could not connect to database: $DBI::errstr";

# so the cookie file is store next to the script
my $script_dir = $FindBin::Bin;
chdir($script_dir);

login();
get_calls();

$dbh->disconnect(); 

#
# get the list of answered and missed calls
#
sub get_calls {

		my $url = "https://sam.sso.bluewin.ch/my/data/VoipBlacklist?mode=showCallList";
		my $request = GET $url;
		my $response = $ua->request($request);

		if (!$response->is_success) {
				print Dumper($response);
				die "Failed to get url - $response->code, $response->status_line";
		}
#		print $response->content, "\n";

		my $dom = Mojo::DOM->new;
		$dom->parse($response->content);
    # table id=incommingCallTable/tbody/tr

		my $tr;

	  print "Incoming calls\n";

		my $sth_insert = $dbh->prepare("insert into answered_calls (date,number) values(?,?)");
		my $sth_select = $dbh->prepare("select id from answered_calls where date=? and number=?");
    my $line=0;
	  for $tr ($dom->find('table[id=incommingCallTable] tr')->each) {
	  	# first 2 lines are headers
	  	next if $line++ < 2;
#	  	print "--- Line $line\n";
#	  	say $tr->children('td.text.line')->pluck('text')->join(', ');
			my $date = $tr->children('td.text.line')->[0]->text;
			my $phone = $tr->children('td.text.line')->[1]->text;
			my $parsed_date = strptime('%d.%m.%Y %H:%M', $date);
			print "$date ($parsed_date) => $phone ";
			$sth_select->execute($parsed_date, $phone);
			if ($sth_select->rows == 0) {
				$sth_insert->execute($parsed_date, $phone);
				print " inserted\n";
			} else {
				print " not inserted\n";
			}
			
#	  	for my $td ($tr->children('td')->each) {
#		  	print "TD:" . $td->text . "\n";
#		  }
	  }

		$sth_insert->finish(); 
		$sth_select->finish(); 
	  $line = 0;
		
		my @missed_calls = ();
		
		$sth_insert = $dbh->prepare("insert into missed_calls (date,number) values(?,?)");
		$sth_select = $dbh->prepare("select id from missed_calls where date=? and number=?");
	  print "\n\nMissed calls\n";
	  for $tr ($dom->find('table[id=missedCallsTable] tr')->each) {
	  	# first 2 lines are headers
	  	next if $line++ < 2;
#	  	print "--- Line $line\n";
#	  	say $tr->children('td.text.line')->pluck('text')->join(', ');
			my $date = $tr->children('td.text.line')->[0]->text;
			my $phone = $tr->children('td.text.line')->[1]->text;
			my $parsed_date = strptime('%d.%m.%Y %H:%M', $date);
			$sth_select->execute($parsed_date, $phone);
			print "$date ($parsed_date) => $phone ";
			if ($sth_select->rows == 0) {
				print " inserted\n";
				$sth_insert->execute($parsed_date, $phone);
				$phone =~ s/\+41 /0/gi;
				push @missed_calls, $phone;
			} else {
				print " not inserted\n";
			}
#	  	for my $td ($tr->children('td')->each) {
#		  	print "TD:" . $td->text . "\n";
#		  }
	  }
	  
	  my @unique = do { my %seen; grep { !$seen{$_}++ } @missed_calls };
	  my $num_calls = scalar(@unique);
	  print "New missed calls: $num_calls\n";
	  if ($num_calls > 0) {
	  	my $message = $num_calls . " appel" . ($num_calls > 1 ? "s":"") . " en absence (" . join(', ', @unique) . ")";
			send_notification('Appels', $message);
	  }
}

sub login {

    my $url = 'https://sam.sso.bluewin.ch/my/data/MyData?lang=en&amp;service=MyData&amp;mode=';

    my %parameters = (method => 'POST',
    									count_tries => '0',
                      username => $swisscom_login,
                      password => $swisscom_pwd,
                      p => 1);

    my $request = POST $url, \%parameters;
    $request->content_type('application/x-www-form-urlencoded;charset=utf-8');
    my $response = $ua->request($request);

    if (!$response->is_success) {
    		print Dumper($response);
        die "Failed to get url - $response->code, $response->status_line";
    }

#    print $response->content, "\n";
}

sub send_notification ($$) {
	my ($application, $notification) = @_;

	my ($userAgent, $request, $response, $requestURL);
	$userAgent = LWP::UserAgent->new;
	$userAgent->agent("ProwlScript/1.2");
	$userAgent->env_proxy();

		$requestURL = sprintf("https://prowlapp.com/publicapi/add?apikey=%s&application=%s&event=%s&description=%s&priority=%d&url=%s",
						PROWL_API_KEY,
						$application,
						'', 			# $options{'event'},
						uri_escape($notification),
						0, 				# $options{'priority'},
						'', 			# $options{'url'}
						);

		$request = HTTP::Request->new(GET => $requestURL);

		$response = $userAgent->request($request);

		if ($response->is_success) {
			print "Notification successfully posted.\n";
		} elsif ($response->code == 401) {
			print STDERR "Notification not posted: incorrect API key.\n";
		} else {
			print STDERR "Notification not posted: " . $response->content . "\n";
		}
}