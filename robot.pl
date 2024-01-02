#!/usr/bin/perl

use strict;
use LWP::Simple;
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;

my $SERVER = 'eu.undernet.org';
my $PORT = '6667';
my $NICK = 'BotRSS';
my $USER = 'news';
my $CHAN = '#gptmoe';



our %BOT_RSS = (
    '#test' => {
	'tosh-codes' => {
	    'rss' => undef,
	    'url' => 'http://tosh-codes.tuxfamily.org/wordpress/?feed=rss',
	    'last_date' => '',
	    'last_update' => time()
	},	
		
    },
    
    );

my @BOT_CONN = ($SERVER, $PORT, [keys %BOT_RSS], $NICK, $USER);
my %ANTI_FLOOD;

use constant {
    NORMAL      => "\x0f",

    # formatting
    BOLD        => "\x02",
    UNDERLINE   => "\x1f",
    REVERSE     => "\x16",
    ITALIC      => "\x1d",
    FIXED       => "\x11",

    # colors
    WHITE       => "\x0300",
    BLACK       => "\x0301",
    DARK_BLUE   => "\x0302",
    DARK_GREEN  => "\x0303",
    RED         => "\x0304",
    BROWN       => "\x0305",
    PURPLE      => "\x0306",
    ORANGE      => "\x0307",
    YELLOW      => "\x0308",
    LIGHT_GREEN => "\x0309",
    TEAL        => "\x0310",
    CYAN        => "\x0311",
    LIGHT_BLUE  => "\x0312",
    MAGENTA     => "\x0313",
    DARK_GREY   => "\x0314",
    LIGHT_GREY  => "\x0315",
};

######################################
# MAIN                               #
######################################
IRCMod::AddHandler("PING",    \&ping_handle);
IRCMod::AddHandler("376",     \&end_names_handle);
IRCMod::AddHandler("PRIVMSG", \&privmsg_handle);

while(1) {
    IRCMod::Connect(@BOT_CONN);
    IRCMod::EventLoop();
    warn "Connexion lost !\n";
}

#########################################
# HANDLERS                              #
#########################################
sub ping_handle {
    my $msg = shift;
    IRCMod::SendMsg('PONG :' . $msg->{data});
    rss_update();
}

sub end_names_handle {
    foreach my $chan(@IRCMod::Channels) {
	IRCMod::SendMsg("JOIN $chan");
    }
}

sub privmsg_handle {
    my $msg = shift;
    my $arg = $msg->{args};
    my $chan = $arg->[0];

    rss_update();
    
    if(is_irc_channel($chan)) {
        my ($cmd, @arg) = split / /, $msg->{data};
        if($cmd && $cmd =~ m/^!/) {

            unless(is_flood($msg)) {
                $cmd = substr($cmd, 1);

                if(exists($BOT_RSS{$chan}{$cmd})) {
                    send_rss($arg->[0], $cmd, 3);
                } else {
                    IRCMod::SendPrivmsg($chan, 
                                        "Commands : !" . 
                                        join(', !', keys(%{$BOT_RSS{$chan}})));
                }
            }
        }
    }
}

############################################
# MISC functions                           #
############################################
sub is_irc_channel {
    return $_[0] =~ m/^#(\S+)$/;
}

sub delete_old_flood_entries {
    foreach my $chan(keys %ANTI_FLOOD) {
        foreach my $host(keys %{$ANTI_FLOOD{$chan}}) {
            if(time - $ANTI_FLOOD{$chan}{$host}{'timestamp'} > 12) {
                delete $ANTI_FLOOD{$chan}{$host};
            }
        }
    }
}

sub is_flood {
    my $msg = shift;
    my $chan = $msg->{args}[0];
    my $host = $msg->{host};

    delete_old_flood_entries();

    $ANTI_FLOOD{$chan}{$host}{'msgs'}++;
    $ANTI_FLOOD{$chan}{$host}{'timestamp'} = time;

    if($ANTI_FLOOD{$chan}{$host}{'msgs'} > 3) {
        return 1;
    }

    return 0;
}

############################################
# RSS functions                            #
############################################
sub parse_rss_date {
    my $date = shift;

    if($date =~ m/(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/) {
        return "le $3/$2/$1 ? $4". "h$5";
    }
    if($date =~ m/(.+) \+0000/) {
        return $1;
    }
    return $date;
}

sub get_rss_date {
    my $it = shift;
    my $key;

    $key = 'dc:date' if(exists $it->{'dc:date'});
    $key = 'pubDate' if(exists $it->{'pubDate'});
    $key = 'date_timestamp' if(exists $it->{'date_timestamp'});

    return undef unless(defined $key);
    return $it->{$key};
}

sub get_rss_title {
    my $it = shift;
    my $key;

    $key = 'title' if(exists $it->{'title'});

    return undef unless(defined $key);
    return $it->{$key};
}

sub get_rss_author {
    my $it = shift;
    my $key;

    $key = 'dc:creator' if(exists $it->{'dc:creator'});
    
    return undef unless(defined $key);
    return $it->{$key};
}

sub get_rss_link {
    my $it = shift;
    my $key;

    $key = 'link' if(exists $it->{'link'});
    
    return undef unless(defined $key);
    return $it->{$key};
}

################################################
# RSS displayer                                #
################################################
sub send_rss {
    my ($chan, $type, $n) = @_;
    
    for(1..$n) {
        my $rss = $BOT_RSS{$chan}{$type}{rss};

        if($rss->{channel}{item}[$_]) {
            my $item = $rss->{channel}{item}[$_ - 1];
            my $msg;
            my $date = get_rss_date($item);
            my $author = get_rss_author($item);
            my $title = get_rss_title($item);
            my $link = get_rss_link($item);

            $msg .= DARK_GREY . " [" . BOLD . ($type) . NORMAL . DARK_GREY . "] : ";
            $msg .= NORMAL . LIGHT_BLUE . $title if($title);
            $msg .= " - " . PURPLE . "Author" . LIGHT_BLUE . " : " . $author if($author);
            $msg .= " - " . PURPLE . "Date"   . LIGHT_BLUE . " : " . parse_rss_date($date) if($date);
            $msg .= " - " . PURPLE . "Link"   . LIGHT_GREY . " : " . $link if($link);
            IRCMod::SendPrivmsg($chan, $msg);
        }
    }
}

###############################################
# RSS Update                                  #
###############################################
sub get_rss {
    my ($url, $user, $pass) = @_;
    my $page;
    my $ua;
    my $serv;

    # URL de la forme http://serveur/
    ($serv) = $url =~ m/http:\/\/(\S+:\d+)\//;

    # URL de la forme http://serveur:port/
    ($serv) = $url =~ m/http:\/\/(\S+)\// if(!$serv);

    if(!$serv) {
        warn("Bad URL !\n");
        return undef;
    }

    # Timeout of 6 seconds.
    eval {
        local $SIG{ALRM} = sub { die("Get() timeout !\n"); };
        alarm 6;
        $ua = LWP::UserAgent->new();
        $ua->credentials($serv, "realm-name", $user, $pass) if($user && $pass);
        $page = $ua->get($url);
        $page = $page->content;
    };
    alarm 0;
    $page = undef if($@);
    return $page;
}

sub rss_update {
    foreach my $chan(keys %BOT_RSS) {

	foreach my $key(keys %{$BOT_RSS{$chan}}) {
            my $rss = $BOT_RSS{$chan}{$key};

	    if($rss->{last_update} + 120 < time() || 
               !defined $rss->{rss}) {

		my $html = get_rss($rss->{url}, $rss->{user}, $rss->{pass});
		if(defined $html) {
		    my $date;

		    $rss->{rss} = XMLin($html);
		    $date = get_rss_date($rss->{rss}{channel}{item}[0]);

		    if($date && $rss->{last_date} ne $date) {
			if($rss->{last_date} ne '') {
			    send_rss($chan, $key, 1);
			}
			$rss->{last_date} = $date;
		    }
		}
		$rss->{last_update} = time();
	    }
	}
    }
}

###################################################################################
################################## IRC MODULE #####################################
###################################################################################

package IRCMod;

use IO::Socket::INET;
use strict;

my $sock;
my %cmd_handler;
our @Channels;

sub _connect_with_timeout {
    my ($serv, $port) = @_;
    eval
    {
        local $SIG{ALRM} = sub { die("Connect() timeout !\n"); };
        alarm 8;
        $sock = IO::Socket::INET->new(PeerAddr => $serv,
                                      PeerPort => $port,
                                      Proto    => 'tcp');
    };
    alarm 0;
    $sock = undef if($@);
}

sub Connect {
    my ($serv, $port, $chans, $nick, $user) = @_;
    @Channels = @$chans;
    
    do {
        print "Trying to connect to $serv:$port...\n";
        _connect_with_timeout($serv, $port);
        if(!$sock) {
            print "Unable to conntect to $serv:$port.\n";
            sleep(3);
        }
    }while(!$sock);

    SendMsg("NICK $nick");
    SendMsg("USER $user $user $user :$user");
}

sub AddHandler {
    my ($name, $handler) = @_;
    $cmd_handler{$name} = $handler;
}

sub _recv_with_timeout {
    my $data;
    eval {
        local $SIG{ALRM} = sub { die("Recv() timeout !\n"); };
        alarm 300;
        $data = <$sock>;
    };
    alarm 0;
    return undef if($@);
    return $data;
}

sub EventLoop {

    while(my $data = _recv_with_timeout()) {
        if(defined $data) {
            print "<== $data";
            my $msg = _parse_irc_msg($data);

            if(exists($cmd_handler{$msg->{cmd}})) {
                my $fun = $cmd_handler{$msg->{cmd}};
                $fun->($msg);
            }
        }
    }
}

sub _parse_irc_msg {
    my $msg = shift;
    my %parsed_msg;
    my @args;
    my $i;
    my @arg_msg;

    $msg = substr($msg, 0, (length $msg)-2) if($msg =~ m/\r\n$/);
    @args = split /\s+/, $msg;

    if($msg =~ m/^:/) {
        $parsed_msg{from} = shift @args;
        $parsed_msg{cmd} = shift @args;
    } else {
        $parsed_msg{cmd} = shift @args;
    }

    for($i = shift @args; $i && $i !~ m/^:/; $i = shift @args) {
        push (@arg_msg, $i);
    }
    $parsed_msg{data} = join(' ', substr ($i, 1), @args) if($i);
    $parsed_msg{args} = \@arg_msg;
    ($parsed_msg{nick}) = ((lc $parsed_msg{from}) =~ m/:(.+)\!/) if($parsed_msg{from});
    ($parsed_msg{host}) = ($parsed_msg{from} =~ m/\@(.+)/) if($parsed_msg{from});
    
    return \%parsed_msg;
}

sub SendMsg {
    my $msg = shift;
    print "==> $msg\n";
    print $sock "$msg\r\n";
}

sub SendPrivmsg {
    my ($channel, $msg) = @_;

    SendMsg("PRIVMSG $channel :$msg");
}

1;

=pod

=head1 NAME

RSSbot - An IRC bot which can read RSS feeds and display them on channel

=head1 SYNOPSIS

perl robot.pl

=head1 DESCRIPTION

RSSbot is an IRC bot used for displaying RSS feeds on a channel.
You can modifie settings by editing the robot.pl file.

For start, it was a project developped for root-me.org plateform, but
now, it can be used for other purposes.


=head1 VERSION

V1.0

=head1 AUTHOR

Written by B<Tosh>

(duretsimon73 -at- gmail -dot- com)


=head1 LICENCE

This program is a free software. 
It is distrubued with the terms of the B<GPLv3 licence>.

=cut
