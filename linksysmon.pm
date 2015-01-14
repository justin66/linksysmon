# ============================================================================
# Copyright (C) 2002 Michael J. Wohlgemuth. All rights reserved; 
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ============================================================================

package linksysmon;

use strict;
use Carp;
use vars qw($VERSION $AUTOLOAD);

$VERSION = '1.1.3';

my %fields = (    
		  TrapdPath        => '/usr/sbin/snmptrapd',
		  LogFile          => '/var/log/linksys.log',
		  AlternateLogFile => '',
		  Delimiter        => "\t",
		  ProcessIPChanges =>  1,
		  IPChangeProgram  => '/usr/sbin/linksysmon-ipchange',
		  MailTo           => 'root\@localhost',
		  MailPath         => '/bin/mail',
		  EZPath           => '/usr/sbin/ez-ipupdate',
		  EZHost           => undef, 
		  ReportIgnoreOutbound   => 1,
		  ReportIgnoreSystem     => 1,
		  ReportIgnorePorts      => undef,
		  ReportIgnoreHosts      => undef,
		  ReportCountRepeats     => 1,
		  WatchPorts       => undef,
		  WatchHosts       => undef,
		  WatchIgnorePorts => undef,
		  WatchIgnoreHosts => undef,
		  WatchProgram     => '/usr/sbin/linksysmon-watch',
                  WatchMailTo      => 'root\@localhost',
		  WatchTimeOut     => 3600,
		  );

sub _stripconfig {
    
# Given an array that contains a config file, strip out any blank
# lines or comments, and combine any multi-line entries

    my @configarray = @{ shift (@_) };
    my $i;

    @configarray = grep (!/^\s*\#/, @configarray);
    @configarray = grep (!/^\s*$/, @configarray);

    chomp (@configarray);

# If the line ends in "\" we want to drop the "\" and append the next
# line to it.

    for ($i = @configarray - 2; $i >= 0; $i--) {
        if ($configarray[$i] =~ /^(.*)\\\s*$/) {
            $configarray[$i] = "$1 $configarray[$i + 1]";
            splice (@configarray, $i + 1, 1);
        }
    }

    return (@configarray);
}

sub new {

    my $self = shift;
    my $class = ref($self) || $self;

    my $configfile = '/etc/linksysmon.conf';
    $configfile = shift if @_ % 2;

    my $obj = {
	_permitted=>\%fields,
	%fields,
    };

    bless $obj, $class;

    my @config;
    my $line;
    my $ezhost;

    open (CONFIG, $configfile) ||
        croak "Unable to open configuration file: $configfile\n";

    @config = <CONFIG>;

    close (CONFIG);

    @config = &_stripconfig (\@config);

    foreach $line (@config) {

	$line =~ s/\s*$//;

      SWITCH: {
	  
# TrapdPath <filename>

          $line =~ /^\s*TrapdPath\s+(.+)$/  && do {

              $obj->{'TrapdPath'} = $1;

              last SWITCH;
          };

# LogFile <filename>

          $line =~ /^\s*LogFile\s+(.+)$/  && do {

              $obj->{'LogFile'} = $1;

              last SWITCH;
          };

# AlternateLogFile <filename>

          $line =~ /^\s*AlternateLogFile\s+(.+)$/  && do {

              $obj->{'AlternateLogFile'} = $1;

              last SWITCH;
          };

# Delimiter <string>

          $line =~ /^\s*Delimiter\s+(.+)$/  && do {

              $obj->{'Delimiter'} = $1;

	      if ($obj->{'Delimiter'} eq 'tab') {
		  $obj->{'Delimiter'} = "\t";
	      }
              last SWITCH;
          };

# ProcessIPChanges <0|1>

          $line =~ /^\s*ProcessIPChanges\s+(0|1)$/  && do {

              $obj->{'ProcessIPChanges'} = $1;

              last SWITCH;
          };

# IPChangeProgram <filename>

          $line =~ /^\s*IPChangeProgram\s+(.+)$/  && do {

              $obj->{'IPChangeProgram'} = $1;

              last SWITCH;
          };

# MailTo <email address>

          $line =~ /^\s*MailTo\s+(.+)$/  && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'MailTo'} = \@a;

              last SWITCH;
          };

# MailPath <filename>

          $line =~ /^\s*MailPath\s+(.+)$/  && do {

              $obj->{'MailPath'} = $1;

              last SWITCH;
          };

# EZPath <filename>

          $line =~ /^\s*EZPath\s+(.+)$/  && do {

              $obj->{'EZPath'} = $1;

              last SWITCH;
          };

# <EZHost hostname>

	  $line =~ /^\s*<EZHost\s*(.+)\s*>$/  && do {

              $ezhost = $1;

              last SWITCH;
          };

# </EZHost>

          $line =~ m-^\s*</EZHost>$-  && do {
	      
              if ($ezhost ne "") {
                  $ezhost = "";
              }
              else {
                  croak "</EZHost> without <EZHost>\n";
              }
	      
              last SWITCH;
          };
          
# DNSName <dynamic hostname>

          $line =~ /^\s*DNSName\s+(.+)$/  && do {
	      
	      if ($ezhost ne "") {
		  $obj->{'EZHost'}{$ezhost}{'DNSName'} = $1;
	      }
	      else {
		  croak "Error: DNSName must appear in <EZHost> block\n";
	      }

              last SWITCH;
          };
	  
# DNSService <dynamic DNS service name>
	  
          $line =~ /^\s*DNSService\s+(.+)$/  && do {
	      
	      if ($ezhost ne "") {
		  $obj->{'EZHost'}{$ezhost}{'DNSService'} = $1;
	      }
	      else {
		  croak "Error: DNSService must appear in <EZHost> block\n";
	      }
	      
              last SWITCH;
          };
	  
# UserName <dynamic DNS user name>

          $line =~ /^\s*UserName\s+(.+)$/  && do {

	      if ($ezhost ne "") {
		  $obj->{'EZHost'}{$ezhost}{'UserName'} = $1;
	      }
	      else {
		  croak "Error: UserName must appear in <EZHost> block\n";
	      }

              last SWITCH;
          };

# Password <dynamic DNS password>

          $line =~ /^\s*Password\s+(.+)$/  && do {

	      if ($ezhost ne "") {
		  $obj->{'EZHost'}{$ezhost}{'Password'} = $1;
	      }
	      else {
		  croak "Error: Password must appear in <EZHost> block\n";
	      }

              last SWITCH;
          };
 
# IgnoreOutbound <0|1> **** Depricated, Use ReportIgnoreOutbound

          $line =~ /^\s*IgnoreOutbound\s+(0|1)$/  && do {

              $obj->{'ReportIgnoreOutbound'} = $1;

              last SWITCH;
	  };

# IgnoreSystem <0|1> **** Depricated, Use ReportIgnoreSystem

          $line =~ /^\s*IgnoreSystem\s+(0|1)$/  && do {

              $obj->{'ReportIgnoreSystem'} = $1;

              last SWITCH;
          };

# IgnorePorts <list of ports> **** Depricated, Use ReportIgnorePorts

	  $line =~ /^\s*IgnorePorts\s+(.+)$/ && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'ReportIgnorePorts'} = \@a;

	      last SWITCH;
	  };

# IgnoreHosts <list of hosts> **** Depricated, Use ReportIgnoreHosts

	  $line =~ /^\s*IgnoreHosts\s+(.+)$/ && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'ReportIgnoreHosts'} = \@a;

	      last SWITCH;
	  };

# ReportIgnoreOutbound <0|1>

          $line =~ /^\s*ReportIgnoreOutbound\s+(0|1)$/  && do {

              $obj->{'ReportIgnoreOutbound'} = $1;

              last SWITCH;
	  };

# ReportIgnoreSystem <0|1>

          $line =~ /^\s*ReportIgnoreSystem\s+(0|1)$/  && do {

              $obj->{'ReportIgnoreSystem'} = $1;

              last SWITCH;
          };

# ReportIgnorePorts <list of ports>

	  $line =~ /^\s*ReportIgnorePorts\s+(.+)$/ && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'ReportIgnorePorts'} = \@a;

	      last SWITCH;
	  };

# ReportIgnoreHosts <list of hosts>

	  $line =~ /^\s*ReportIgnoreHosts\s+(.+)$/ && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'ReportIgnoreHosts'} = \@a;

	      last SWITCH;
	  };

# ReportCountRepeats <0|1>

          $line =~ /^\s*ReportCountRepeats\s+(0|1)$/  && do {

              $obj->{'ReportCountRepeats'} = $1;

              last SWITCH;
	  };

# WatchPorts <list of ports>

	  $line =~ /^\s*WatchPorts\s+(.+)$/ && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'WatchPorts'} = \@a;

	      last SWITCH;
	  };

# WatchHosts <list of hosts>

	  $line =~ /^\s*WatchHosts\s+(.+)$/ && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'WatchHosts'} = \@a;

	      last SWITCH;
	  };

# WatchIgnorePorts <list of ports>

	  $line =~ /^\s*WatchIgnorePorts\s+(.+)$/ && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'WatchIgnorePorts'} = \@a;

	      last SWITCH;
	  };

# WatchIgnoreHosts <list of hosts>

	  $line =~ /^\s*WatchIgnoreHosts\s+(.+)$/ && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'WatchIgnoreHosts'} = \@a;

	      last SWITCH;
	  };

# WatchProgram <filename>

          $line =~ /^\s*WatchProgram\s+(.+)$/  && do {

              $obj->{'WatchProgram'} = $1;

              last SWITCH;
          };

# WatchMailTo <email address>

          $line =~ /^\s*WatchMailTo\s+(.+)$/  && do {

	      my @a = split (/\s*,\s*/, $1);
	      $obj->{'WatchMailTo'} = \@a;

              last SWITCH;
          };

# WatchTimeOut <seconds>

          $line =~ /^\s*WatchTimeOut\s+(.+)$/  && do {

              $obj->{'WatchTimeOut'} = $1;

              last SWITCH;
          };

          croak "Unrecognized or malformed configuration directive: $line\n";

      }
    }

    return $obj;
}

sub DESTROY {

# I have to have this or perl calls AUTOLOAD for DESTROY, and that is
# bad.

}

sub AUTOLOAD {

# This is pretty much taken from the "Programming Perl, 2nd Edition"
# example on pages 298-299, except we don't allow setting the
# variable, just getting it.

    my $self = shift;
    my $class = ref($self) || croak "$self is not an object";

    my $name = $AUTOLOAD;
    
    $name =~ s/.*://;    # strip fully-qualified portion

    unless (exists $self->{_permitted}->{$name}) {
	croak "Can't access '$name' field in object of class $class";
    }

    return $self->{$name};	
}

1;
