#!/usr/bin/perl -w

use POE;
use POE::Component::IRC;
use HTML::HeadParser;
use HTTP::Request;
use HTTP::Headers;
use LWP::UserAgent;
use URI::Escape;
use utf8;
my $lastline;
$urlspam = 0;
my $server = "localhost";
my $nick = "Y55";
my $name = "THE NEW AND IMPROVED Y55!!!!!";
#my $channels = "#chshackers,#osu";
@channels = ("#chshackers","#botfucking","#osu");
@ignored = ("Fishbot");
$irc = POE::Component::IRC->new("irc");

POE::Session->new
    ( _start => \&bot_start,
      irc_public => \&on_public,
      irc_msg => \&on_msg,
      irc_kick         => \&kicked,
      irc_disconnected => \&bot_reconnect,
      irc_error        => \&bot_reconnect,
      irc_socketerr    => \&bot_reconnect,
      irc_001          => \&irc_join,
#      irc_372          => \&irc_motd,
      irc_433          => \&irc_handlenick,
      );
sub irc_motd {
    my $msg = $_[ARG1];

    print "MOTD: $msg\n";
}

sub kicked {
    if (@_[ARG2] =~ /Y55/) {
	&irc_rejoin;
    }
}
sub irc_handlenick {
    
}

sub bot_start {
    my $kernel = $_[KERNEL];
    my $heap = $_[HEAP];
    my $session = $_[SESSION];

    $kernel->post(irc => register => 'all');
    $kernel->post(irc => 'connect' =>
		{ Nick     => $nick,
		  Server   => $server,
		  Port     => "6667",
		  Flood	   => 1,
		  Username => $nick,
		  Ircname  => $name, } );
    $kernel->post(irc => oper => 'y55', 'y55rox');
}

sub irc_join {

    my $kernel = $_[KERNEL];
    my $jointhis;
    foreach $jointhis(@channels) {
	print "joining channel $jointhis\n";
	$kernel->post(irc => 'join' => $jointhis );
    }
}
sub irc_rejoin {

    my $kernel = $_[KERNEL];
	print "rejoining channel $_[ARG1] due to kick\n";
	$kernel->post(irc => 'join' => $_[ARG1] );
}

sub bot_reconnect {
    my $kernel = $_[KERNEL];
    $kernel->post( irc => connect =>
		   { Nick     => $nick,
		     Server   => $server,
		     Port     => "6667",
		     Username => $nick,
		     Flood => 1,
		     Ircname  => $name, } );
    $kernel->post(irc => oper => 'y55', 'y55rox');
 }
sub oper { 
    my $kernel = $_[KERNEL]; 
    $kernel->post(irc => oper => 'y55', 'y55rox');
}
sub openfile {
    my $string = shift;
    $data = "";
    if(open(FD, $string)) {
        while($stream = <FD>) {
            $data .= $stream;
            @data = split(/\n/, $data);
        }
        close(FD);
    }
    return $data;
}

sub on_public {
    my ($kernel, $sender, $channel, $msg) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    $sender =~ s/(^.*)\!.*/$1/;
    if (!($sender =~ /([fF]ishbot.*|Oublei.*|Emou.*|Oup)/i)){
    my $returnstring = uber($msg, $sender);
    if ($returnstring) {
#	$returnstring .= "Ã¨Â±Â";
	print "Public message from: $sender\n";
	@say = split("\n", $returnstring);
	foreach $messay(@say) {
	    $kernel->post(irc => privmsg => $channel, $messay);
	}
    }
}
}

sub on_msg {
    my ($kernel, $sender, $adressed, $msg) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    $sender =~ s/(^.*)\!.*/$1/;
    if (!($sender =~ /Kyle.*/)) {
	my $returnstring = uber ($msg, $sender);
	if ($returnstring) {
	    print "Private message from: $sender\n";
	    @say = split("\n", $returnstring);
	    foreach $messay(@say) {
		$kernel->post(irc => privmsg => $sender, $messay);
	    }
	}
    }
}
sub uber {
    my $msg = shift();
    my $sender = shift();
    my $print = 0;    


    if ($msg =~ /^\!/) {
	$output = module ($msg, $sender);	
	return $output;
    }
    
    $urlspam = false;
    if ($msg =~ /(^|[ ]|((http):\/\/))(([0-9]+\.[\d]+\.[\d]+\.[0-9]+)|localhost|([\w\d\-]+\.)*[\w\d\-]+\.(com|net|org|info|biz|gov|name|edu|[\w][\w]))(:[\d]+)?(((\/|\?|&)[^ \"]*)?[^ ,;\.:\">)])?/) {
	print "$msg from $sender\n";
	if (!($sender =~ /[fF]ishbot.*/)) {
	    $url = $1 . $4 . $8 . $9;
	    $p = HTML::HeadParser->new();
	    if (!($url =~ /^http:\/\//)) {
		$url = "http://" . $url;
	    }
	    print "Trying: $url\n";
	    $request = HTTP::Request->new(HEAD => $url); 
	    $ua = LWP::UserAgent->new();
	    $ua->agent('Mozilla/5.0');
	    $timeoutsecs = "30";
	    $ua->timeout( $timeoutsecs );
	    $response = $ua->request($request);
	    if ($response->is_success && $response->header('Content-Type') =~ /html/) {
		$request = HTTP::Request->new(GET => $url);
		print "Fetching: $url\n";
		$response = $ua->request($request);
		$p->parse($response->content);
		return "Title: " . $p->header('Title');
	    } 
	    elsif ($response->is_success) {
		print "Type: " . $response->header('Content-Type') . "\n";
		return "Type: " . $response->header('Content-Type');
	    }
	}
    }
}

sub runmod {
    print "Starting runmod\n";
    $modrun = shift;
    print "$modrun\n";
#    print "$sender: $msg";
    $neat = eval $modrun;
    return "$neat";
}

sub module {
$msg = shift();
$sender = shift();
    $modname = $msg;
    $modname =~ s/^\!(\w*).*/$1/;
    $base_path = "./modules";
    @modules = <$base_path . /$modname>;
    if (@modules){
	print "loading module $modname\n";
	@module = openfile ("./modules/$modname");
	if (@module){ 
#	    print "#######\n";
#	    print "@module\n";
#	    print "#######\n";
	    print "running the runmod subroutine\n";
	    $cool = runmod (@module);	
	}
#	@omg = split("\n",$cool);
    }
    else { 
	print "OMG NO MODULE FOUND"; 
    }
    print $cool;
    return $cool;
}

sub process_ft {
    $feet = shift();
    $hundred = $feet %10;
    $thousand = ($feet - $hundred) / 10;
    if ($thousand) {
	$thousand = $thousand . " thousand ";
    } else {
        $thousand = "";
    }
    if ($hundred) {
	$hundred = $hundred . " hundred ";
    } else {
        $hundred = "";
    }

    return $thousand . $hundred;
}

sub handle_taf {
    $tafstring = shift();
    chomp($tafstring);
    $tafstring = $tafstring . " ";
    $tafstring =~ s/([0-9]{2})([0-9]{2})([0-9]{2})(Z|z)\s/Issued on \1 at \2:\3 : /;
    $tafstring =~ s/FM([0-9]{2})([0-9]{2})\s/After \1:\2 /;
    $tafstring =~ s/TEMPO ([0-9]{2})([0-9]{2})\s/with \1:00 to \2:00 occasional /;
    $tafstring =~ s/BECMG ([0-9]{2})([0-9]{2})\s/Gradually changing between \1:00 and \2:00 to /;
    $tafstring =~ s/([0-9]{2})([0-9]{2})([0-9]{2})\s/Effective on \1 from \2:00 hours to \3:00 hours /;
    $tafstring =~ s/00000KT\s/Wind calm /;
    $tafstring =~ s/(VRB|[0-9]{3})([0-9]{2})(G([0-9]{2}))?KT\s/Wind \1 at \2 knots\3 /;
    $tafstring =~ s/VRB/variable/;
    $tafstring =~ s/G([0-9]{2})\s/ gust at \1 knots /;
    $tafstring =~ s/(P)?([0-6]|([0-5]\s)?[0-9]\/[0-9])SM\s/Visibility \1\2 statute mile(s) /;
    $tafstring =~ s/P6/more than 6/;
    $tafstring =~ s/SKC\s/Sky clear /;
    while ($tafstring =~ /((\+|-|VC)?(MI|BC|DR|BL|SH|TS|FZ|PR|DZ|RA|SN|SG|IC|PL|GR|GS|UP|BR|FG|FU|DU|SA|HZ|PY|VA|PO|SQ|FC|SS|DS)+)\s/) {
#       print "doing weather: '$1'\n";                                                                              $out = "weather: ";
        if ($1 eq "+FC") {$out = "!!well-developed funnel cloud, tornado or waterspout!!"; $1 = ""}
        $out = $3;
        $modifier = $2;
        $out =~ s/MI/shallow /;
        $out =~ s/BC/patches /;
        $out =~ s/DR/low drifting /;
        $out =~ s/BL/blowing /;
        $out =~ s/SH/showers /;
        $out =~ s/TS/thunderstorm /;
        $out =~ s/FZ/freezing /;
        $out =~ s/PR/partial /;
        $out =~ s/DZ/drizzle /;
        $out =~ s/RA/rain /;
        $out =~ s/SN/snow /;
        $out =~ s/SG/snow grains /;
        $out =~ s/IC/ice crystals /;
        $out =~ s/PL/ice pellets /;
        $out =~ s/GR/hail /;
        $out =~ s/GS/small hail or snow pellets /;
        $out =~ s/UP/unknown precipitation /;
        $out =~ s/BR/mist /;
        $out =~ s/FG/fog /;
        $out =~ s/FU/smoke /;
        $out =~ s/DU/dust /;
        $out =~ s/SA/sand /;
        $out =~ s/HZ/haze /;
        $out =~ s/PY/spray /;
        $out =~ s/VA/volcanic ash /;
        $out =~ s/PO/well-developed dust cloud /;
        $out =~ s/SQ/squalls /;
        $out =~ s/FC/funnel cloud /;
        $out =~ s/SS/sandstorm /;
        $out =~ s/DS/duststorm /;
	
        if ($modifier) {
            if ($modifier eq "+") { $out = "heavy " . $out;}
            if ($modifier eq "-") { $out = "light " . $out;}
            if ($modifier eq "VC") { $out = $out . "in the vicinity ";}
        } else {
            $out = "moderate " . $out;
        }
        $tafstring =~ s/((\+|-|VC)?(MI|BC|DR|BL|SH|TS|FZ|PR|DZ|RA|SN|SG|IC|PL|GR|GS|UP|BR|FG|FU|DU|SA|HZ|PY|VA|PO|SQ|FC|SS|DS)+)\s/$out/;
    }
    
    while ($tafstring =~ /(SCT|BKN|VV|OVC|FEW)([0-9]{3})(CB)?\s/) {
	$ft = process_ft($2);
	$out = "ceiling ";
	if ($1 eq "SCT") {$out .= $ft . "scattered ";}
	if ($1 eq "BKN") {$out .= $ft . "broken ";}
	if ($1 eq "VV") {$out .= "indefinite ceiling " . $ft;}
	if ($1 eq "OVC") {$out .= "overcast " . $ft;}
	if ($1 eq "FEW") {$out .= $ft . "few ";}
	if ($3) {$out .= "cumulonumbus clouds ";}
	$tafstring =~ s/(SCT|BKN|VV|OVC|FEW)([0-9]{3})(CB)?\s/$out/;
    }
    return $tafstring;
}

POE::Kernel->run();
