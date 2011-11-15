#!/usr/bin/perl
# Copyright 2011, Yuriy Syrota <ysyrota@cpan.org>
#
# This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself.

package Net::SMS::AlphaSMS;
our $VERSION = 0.01;
use strict;
use warnings;
use WWW::Curl::Easy;
use URI;
use URI::Escape;
use URI::QueryParam;
use Carp;
use utf8;

=pod

=head1 NAME

Net::SMS::AlphaSMS - Send SMS through AlphaSMS SMS gateway

=head1 SYNOPSIS

 use Net::SMS::AlphaSMS;

 $sms = Net::SMS::AlphaSMS->new(
        login    => 'foo',
        password => 'bar',
 );

 $sms->send_sms(
   from => 'perl',
   to   => $recipient,
   text => 'this text is being sent to you bu Net::SMS::AlphaSMS',
 );

=head1 DESCRIPTION

Net::SMS::AlphaSMS provides a perl object oriented interface to the
AlphaSMS SMS HTTP API, which allows you to send SMS from within your
script or application.

To use this module you must have an AlphaSMS account.

=head1 CONSTRUCTOR

=head2 new( parameters )

=head3 MANDATORY PARAMETERS

=over 8

=item login => $login

Your AlphaSMS login.

=item password => $password

Your AlphaSMS password.

=item key => $key

Your AlphaSMS API key. Login and password will be ignored if key specified.

=back

=head3 OPTIONAL PARAMETERS

=over 8

=item uri

Set an alternative URI to a service implementing the AlphaSMS API.
Default is "http://alphasms.com.ua/api/http.php".

=back

=cut

sub new {
	my $class = shift;
	my $self = {
		uri => 'http://alphasms.com.ua/api/http.php',
		@_,
	};

	bless $self, $class;
	return $self;
}

=head1 METHODS

=head2 send_sms(to=>$recipient, $text=>"msg")

Will send message "msg" as an SMS to $recipient.

$recipient is a telephone number in international format or in local
Ukrainian format.

The $text parameter is the SMS "body". This must be encoded using UTF-8.

The method returns a hash. In case of success the hash contains key "id"
with value set to tracking ID supplied by the SMS gateway. If it failed
then the hash contants key "errors" with array of errors in value.

=cut

sub send_sms {
  my $self = shift;
  my $param = { @_ };

  my %outparam = ();
  $outparam{from } = $param->{from};
  $outparam{to   } = $param->{to} || $self->{to};
  $outparam{text } = $param->{text};
  $outparam{wap  } = $param->{wap} if exists $param->{wap};
  $outparam{flash} = $param->{flash} if exists $param->{flash};
  $outparam{ask_date} = $param->{time} if exists $param->{time};

  return $self->_execute('send', %outparam);
}

=head2 get_delivery_status($id)

Get delivery status of a message.

=over 8

=item id

Tracking ID returned by I<send_sms>

The method returns a hash. In case of success the hash contains keys "code"
with value set to delivery status code and "text" with value set to the
status code text description. If it failed then the hash contants key
"errors" with array of errors in value.

=back

=cut

sub get_delivery_status {
  my ($self, $id) = @_;
  return $self->_execute('receive', id => $id);
}

=head2 get_balance

Get the credit balance for this account from AlphaSMS.

The method returns a hash. In case of success the hash contains key "amount"
with value set to current balance. If it failed then the hash contants key
"errors" with array of errors in value.

=cut

sub get_balance {
  my $self = shift;
  return $self->_execute('balance');
}

sub _execute {
  my ($self, $command, %param) = @_;

  my $base = $self->{uri};
  my $test = $self->{test};

#  my $username = $self->{username};
#  my $password = $self->{password};
#  my $key      = $self->{key};
#  my $sender   = $self->{sender};
#  my $text     = $param->{text};
#  my $to       = $param->{to};

  my $uri = URI->new($base);
  $uri->query_param(version => 'http');
  $uri->query_param(command => $command);

  if (defined $self->{key}) {
    $uri->query_param(key => $self->{key});
  } else {
    $uri->query_param(login => $self->{login});
    $uri->query_param(password => $self->{password});
  }

  foreach my $k (keys %param) {
    $uri->query_param($k => $param{$k});
  }

  my $body;
  if ($self->{test}) {
    if ($command eq 'balance') {
      $body = "balance:0.84\n";
    } elsif ($command eq 'receive') {
      if ($param{id} == 1) { # invalid id
        $body = "errors:SMS not found\n";
      } elsif ($param{id} == 3) { # invalid phone number
        $body = "status:Оператор не поддерживается\ncode:95\nstatus_time:2011-11-15T17:12:33+0200\n";
      } else { # valid number
        $body = "status:Доставлено\ncode:3\nstatus_time:2011-11-15T15:22:26+0200\n";
      }
    } elsif ($command eq 'send') {
      if (!defined($param{to})) {
        $body = "errors:Please enter valid receiver phone number\n";
      } elsif ($param{to} eq '380501234567') { # valid number
        $body = "id:2\nsms_count:1\n";
      } else { # invalid number
        $body = "id:3\nsms_count:1\n";
      }
    } else {
      $body = "errors:Unknown command\n";
    }
  } else {
    my $curl = new WWW::Curl::Easy;
    $curl->setopt(CURLOPT_URL, $uri);
    $curl->setopt(CURLOPT_WRITEDATA, \$body);
    $curl->perform;
  }

  my $response = {};
  if(not defined $body) {
    $response->{errors} = ['SMS gateway does not follow protocol (empty body)'],
   } else {
     my @result = split /[\r\n]+/, $body;
     foreach my $r (@result) {
       my ($key, $value) = split /:/, $r;
       if ($key ne 'errors') {
         $response->{$key} = $value;
       } else {
         $response->{errors} = [] unless (exists $response->{errors});
         push @{$response->{errors}}, $value;
       }
     }
   }
   $response->{uri} = $uri if $self->{test};
   return $response;
}

1;

=head1 SEE ALSO

http://alphasms.com.ua/

=head1 AVAILABILITY

Latest stable version is available on CPAN. Current development
version is available on https://github.com/ysyrota/net-sms-alphasms .

=head1 COPYRIGHT

Copyright (c) 2011,  Yuriy Syrota <ysyrota@cpan.org>
All rights reserved.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

