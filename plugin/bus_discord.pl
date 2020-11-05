#############################################################################
	# bus_discord plugin by sctnightcore
	# @2563
#############################################################################
package bus_discord;
	
use strict;
use Plugins;
use Commands;
use Data::Dumper;
use Log qw( message error );
use Globals;
use Utils;
use AI;

# Plugin
Plugins::register('bus_discord', "send and receive chat of discordd via BUS", \&unload);

my $networkHook = Plugins::addHooks(
	['Network::stateChanged',\&init],
	['packet_privMsg', \&on_private_chat],
	['AI_pre', \&on_ai]
);

my $bus_message_received;

# handle plugin loaded manually
if ($::net) {
	if ($::net->getState() > 1) {
		$bus_message_received = $bus->onMessageReceived->add(undef, \&bus_message_received);
	}
}

sub init {
	return if ($::net->getState() == 1);
	if (!$bus) {
		die("\n\n[bus_discord] You MUST start BUS server and configure each bot to use it in order to use this plugin. Open and edit line \"bus 0\" to bus 1 inside control/sys.txt \n\n");
	} elsif (!$bus_message_received) {
		$bus_message_received = $bus->onMessageReceived->add(undef, \&bus_message_received);
	}
}

sub bus_message_received {
	my (undef, undef, $msg) = @_;
	if (($msg->{messageID} eq 'DISCORD_BOT_PM')) {		
		error Dumper($msg->{args});
		my $user = $msg->{args}->{to};
		my $message = $msg->{args}->{message};
		Commands::run("pm $user $message");
	}
}


sub on_private_chat {
	my (undef, $args) = @_;
	my %data = (
		from => $args->{privMsgUser},
		message => $args->{privMsg}
	);
	$bus->send('BOT_DISCORD_PM', \%data);
}

my %bus_sendinfo_timeout = (timeout => 6);
sub on_ai {
	my (undef, $args) = @_;
	if (timeOut(\%bus_sendinfo_timeout)) {
		if ($char) {
			my %info = (
				name => $char->{name},
				accountID => unpack('V', $accountID),
			);
			$bus->send('BOT_DISCORD_INFO', \%info);
		}
		$bus_sendinfo_timeout{time} = time;
	}
}
# Plugin unload
sub unload {
	message("\n[bus_discord] unloading.\n\n");
	Plugins::delHooks($networkHook);
	$bus->onMessageReceived->remove($bus_message_received) if $bus_message_received;
}
	
1;