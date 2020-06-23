#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

use AnyEvent;
use AnyEvent::IRC::Client;

my $conf = {
    botnick => 'TestBot',
    botuser => 'privacy',
    server  => 'irc.orderofthetilde.net',
    port    => 6667,
    ssl     => 0,
    nsuser  => 'Test',
    nspass  => 'Test',
    chan1   => '#C1',
    chan2   => '#C2',
};


my $cv = AnyEvent->condvar; 
my $con = new AnyEvent::IRC::Client;
my %pnym; # Hash of nick -> pseudonym associations
 
# On end of MOTD
$con->reg_cb(registered => sub { 
    # FIXME: Logging into nickserv is NOT event driven! This is lame but it works most of the time
    # I'd really prefer SASL but AnyEvent::IRC doesn't support it
    $con->send_srv('PRIVMSG', 'NickServ', "IDENTIFY $conf->{'nsuser'} $conf->{'nspass'}");
    sleep(5);

    $con->send_srv("JOIN", "$conf->{'chan1'},$conf->{'chan2'}");
});

# On public message in channel
$con->reg_cb(publicmsg => sub { 
    my ($self, $channel, $ircmsg) = @_;

    # Don't bother with /notice etc. Who cares
    return unless ($ircmsg->{'command'} eq 'PRIVMSG');

    my $nick = $1 if ($ircmsg->{'prefix'} =~ /(.+?)!/); # Extract nick from nick!user@host

    if (lc($channel) eq lc($conf->{'chan1'})) {
        $con->send_srv('PRIVMSG', $conf->{'chan2'}, "<$nick> " . $ircmsg->{'params'}[1]);
    }

    if (lc($channel) eq lc($conf->{'chan2'})) {
        $nick = $pnym{$nick};
        $con->send_srv('PRIVMSG', $conf->{'chan1'}, "<$nick> " . $ircmsg->{'params'}[1]);
    }

});

# You get a pseudonym! You get a pseudonym! EVERYONE GETS A PSEUDONYM!
# Triggered whenever a user is "added" to the channel. Via /names when we join, or when they join
$con->reg_cb(channel_add => sub { 
    my ($self, $msg, $channel, @joinlist) = @_;
    state @nickpool = make_nicks(); # Only executed the first time this is called

    return unless lc($channel) eq lc($conf->{'chan2'});

    foreach (@joinlist) {
        next if $_ eq $conf->{'botnick'};
        $pnym{$_} = $nickpool[ rand @nickpool ];    
        $con->send_srv('PRIVMSG', $conf->{'chan2'}, "$_: Your pseudonym in $conf->{'chan1'} is $pnym{$_}");
    }
});


# Disconnected from IRC? Exit. Untested.
$con->reg_cb (disconnect => sub { exit(1); });
# Kicked from any channel? Exit. Untested.
$con->reg_cb(kick => sub { exit(2) if $_[1] eq $conf->{'botnick'}; });

$con->enable_ssl() if $conf->{'ssl'};
$con->connect ($conf->{'server'}, $conf->{'port'}, { 
    nick => $conf->{'botnick'},
    user => $conf->{'botuser'},
    real => 'https://github.com/madcamel/privacylinkbot'
});
$cv->wait; # Flow control stops here. We are now fully event driven.
    
# Make a bunch of nicknames from /usr/share/dict/american-english
sub make_nicks {
    my (@words, @nicks);

    # Slurp in the word list
    open(IN, '/usr/share/dict/american-english') or die("cannot open /usr/share/dict/american-english: $!");
    while(<IN>) {
        chomp;
	next unless (/^[A-Za-z0-9]+$/); # Only bare words
	next if (length($_) > 6 || length($_) < 3); # Not too long, not too short
	push @words, $_;
    }
    close(IN);

    # Slap a random word on the end of each word from the list. Uppercase each word.
    foreach (@words) {
        push @nicks, ucfirst($_) . ucfirst($words[ rand(@words) ]);
    }

    return @nicks;
}
