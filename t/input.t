#!/usr/bin/perl
use strict;
use utf8;
use Test::More tests => 9;
use Net::SMS::AlphaSMS;

my $sms = Net::SMS::AlphaSMS->new(
	login    => 'login',
	password =>'password',
	test     => 1,
);

# correct input
my $hash = $sms->send_sms(from=>'perl', to=>'380501234567', text=>'hello');
is(
	$hash->{id},
	2,
	"correct input"
);

# check correct delivery status
$hash = $sms->get_delivery_status($hash->{id});
is(
	$hash->{code},
	3,
	"check delivery status of corrent input"
);

# no destination
$hash = $sms->send_sms(from=>'perl', text=>'hello');
is(
	$hash->{id},
	undef,
	"send with no destination"
);
is(
	$hash->{errors}->[0],
	"Please enter valid receiver phone number",
	"receiver phone number message"
);

# check incorrect delivery status
$hash = $sms->get_delivery_status(1);
is(
	$hash->{code},
	undef,
	"checking incorrect delivery status"
);
is(
	$hash->{errors}->[0],
	"SMS not found"
);

# incorrect telephone number format
$hash = $sms->send_sms(to=>'02', from=>'perl', text=>'hello');
is(
	$hash->{id},
	3
);

# check delivery status of incorrect telephone number format
$hash = $sms->get_delivery_status($hash->{id});
is(
	$hash->{code},
	95,
	"checking delivery status of incorrect telephone number format"
);

# check balance
$hash = $sms->get_balance;
is(
	$hash->{balance},
	0.84,
	"check balance"
);


