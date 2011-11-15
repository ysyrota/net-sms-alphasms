#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME => 'Net::SMS::AlphaSMS',
	AUTHOR => 'Yuriy Syrota <ysyrota@cpan.org>',
	LICENSE => 'perl',
	ABSTRACT_FROM => 'lib/Net/SMS/AlphaSMS.pm',
	VERSION_FROM => 'lib/Net/SMS/AlphaSMS.pm',
	
	PREREQ_PM => {
		'WWW::Curl::Easy' => 0,
		'URI' => 0,
		'URI::QueryParam' => 0,
		'URI::Escape' => 0,
	},
);
