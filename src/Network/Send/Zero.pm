#########################################################################
#  OpenKore - Packet sending
#  This module contains functions for sending packets to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
########################################################################
# by alisonrag / sctnightcore
package Network::Send::Zero;

use strict;
use base qw(Network::Send::ServerType0);
use Globals; 
use Network::Send::ServerType0;
use Log qw(error debug message);
use I18N qw(stringToBytes);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);

	my %handlers = qw(
		item_use 0439
		token_login 0825
		send_equip 0998
		master_login 0ACF
	);

	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;

	$self->{char_create_version} = 0x0A39;

	return $self;
}

sub sendMasterLogin {
	my ($self, $username, $password, $master_version, $version) = @_;
	my $msg;
	my $password_rijndael = $self->encrypt_password($password);

	$msg = $self->reconstruct({
		switch => 'master_login',
		game_code => '0036', # kRO Ragnarok game code
		username => $username,
		password_rijndael => $password_rijndael,
		flag => 'G000', # Maybe this say that we are connecting from client
	});

	$self->sendToServer($msg);
	debug "Sent sendMasterLogin\n", "sendPacket", 2;
}

sub reconstruct_char_delete2_accept {
	my ($self, $args) = @_;
	# length = [packet:2] + [length:2] + [charid:4] + [code_length]
	$args->{length} = 8 + length($args->{code});
	debug "Sent sendCharDelete2Accept. CharID: $args->{charID}, Code: $args->{code}, Length: $args->{length}\n", "sendPacket", 2;
}

sub sendCharCreate {
	my ( $self, $slot, $name, $hair_style, $hair_color, $job_id, $sex ) = @_;

	$hair_color ||= 1;
	$hair_style ||= 0;
	$job_id     ||= 0;    # novice
	$sex        ||= 0;    # female

	my $msg = $self->reconstruct({
		switch => 'char_create',
		name => stringToBytes( $name ),
		slot => $slot,
		hair_color => $hair_color,
		hair_style => $hair_style,
		job_id => 0,
		unknown => 0,
		sex => $sex,
	});

	$self->sendToServer($msg);
}

sub sendChat { # 00F3
    my ($self, $message) = @_;
    $message = "|00$message" if $masterServer->{chatLangCode};

    my ($data, $charName); # Type: Bytes
    $message = stringToBytes($message); # Type: Bytes
    $charName = stringToBytes($char->{name});
    $data = pack("C*", 0xF3, 0x00) .
        pack("v*", length($charName) + length($message) + 8) .
        $charName . " : " . $message . chr(0);
    $self->sendToServer($data);
}

1;