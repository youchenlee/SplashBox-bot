#
# SplashBox::Language::Parser Parser.pm 
#
# Copyright (c) 2010-2011  The OpenSplash Team
# http://www.opensplash-project.org/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package SplashBox::Language::Parser;

use strict;
use warnings;

use UUID;
use SplashBox;
use SplashBox::Job::Trigger;

sub new {
	my ($this, %opts) = @_;
	my $class = ref($this) || $this;

	my $self = {};
	bless $self, $class;

	return $self;
}

sub fill_xml {
	my ($self, $raw_xml, $args) = @_;
	my %subsitution_array = split(/[;=]/, $args);

	foreach my $key (keys %subsitution_array){
		$subsitution_array{$key} =~ s/["']//g;
		#print "$key = ";
		#print "$subsitution_array{$key}\n";

		$raw_xml =~ s/{$key}/$subsitution_array{$key}/g;
	}
	return $raw_xml;
}

sub dispatcher {
	my ($self, $action, $args) = @_;
	open (FH, "< $DATA_PATH/action/$action.xml") or die $!;
	undef $/;
	my $raw_xml = <FH>;
	my ($uuid, $uuid_string);
	UUID::generate($uuid);
	UUID::unparse($uuid, $uuid_string);
	my $epoch_seconds = time();

	$raw_xml = $self->fill_xml ($raw_xml, "user='$ENV{USER}';raw='$args';uuid='$uuid_string';create_date='$epoch_seconds'");


	open (FH_WRITE, "> $JOB_PATH/now/$uuid_string.xml") or die $!;
	print FH_WRITE $raw_xml;
	SplashBox::show_log ("File: $JOB_PATH/now/$uuid_string.xml is created!");
	close (FH_WRITE);
	close (FH);
}

sub parser {
	my ($self, $msg) = @_;
	my $is_chat_message = 1;
	my @list_action = <$DATA_PATH/action/*.xml>;
	my $action;
	my @list_time = <$DATA_PATH/time/*.xml>;
	my $time;


	foreach $action (@list_action) {
		$action =~ s#.*/##;
		$action =~ s#\.xml##;

		if ("$msg" =~ /\b$action\b/i )
		{
			SplashBox::show_log ("Got action='$action'");
			$is_chat_message = 0;
			$self->dispatcher ($action, "$msg");
			last;
		}
	}

	foreach $time (@list_time) {
		$time =~ s#.*/##;
		$time =~ s#\.xml##;
		$time =~ s#_# #;

		if ("$msg" =~ /\b$time\b/i )
		{
			SplashBox::show_log ("Got time='$time'");
			last;
		}
	}
	
	SplashBox::Job::Trigger::check_job();
	return $is_chat_message;
}


1;
