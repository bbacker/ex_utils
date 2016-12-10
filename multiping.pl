#!/usr/bin/perl

=pod

=head1 NAME

B<multiping> - check connectivity to a given set of hosts using
several different protocols

=head1 SYNOPSIS

B<multiping> [--verbose=<n>] [--protocols=list]  machine1 [machine2 machine3]

=head1 DESCRIPTION

Use several types of protocols to
see if the list of systems is responsive to each. Finish by
printing a list of which hosts responded to which protocols.

=head2 Protocols

tcp, icmp, udp, syn, external - see perl Net::Ping module for these

external requires an additional Net::Ping::External module to be installed.

http, https - uses LWP::UserAgent to connect via http or https

=head1 OPTIONS

=over 4

=item B<--verbose> <level>

Verbose level: 0, 1, 2, 3, etc.

Verbose level 3 or below shows just final table. 4 or 5 shows
progress, and above 5 dumps the internal struct holding results.
The default is 0.

=item B<--protocols> <string containing list of protocols>

String containing list of protocols to use.
Valid choices are "udp icmp tcp stream syn external http https".
The default is "udp icmp tcp".

=back

=head1 EXAMPLES

multiping oak.rsn.hp.com

multiping -p "http udp" oak.rsn.hp.com

multiping -p "http udp" oak.rsn.hp.com momo-o1.rsn.hp.com  momo-o2.rsn.hp.com

=cut

use strict;
use Net::Ping;
use Carp;
use Data::Dumper;
use Pod::Usage;
use English;
use LWP::UserAgent;


$|++; # make stdout unbuffered

my $verbose=0;
my $protostring;

use Getopt::Long;
# Get the command-line options
GetOptions(
    'verbose=i' => \$verbose,
    'protocols=s' => \$protostring)
or pod2usage();


exit &main(@ARGV);

sub main
{

    my @hostlist = sort @_;
    croak "empty host list" if (! @hostlist);

    my @protolist = qw( tcp udp );
    if ($protostring) {
	$protostring =~ s/^\s+//; # remove leading whitespace
	$protostring =~ s/\s+$//; # remove trailing whitespace
	@protolist = split(/\s+/,$protostring);
    }

    croak "must be root to do icmp checks"
	if (grep (/icmp/, @protolist) && $UID != 0);

    my $rByP = ping_list_by_proto( \@hostlist, \@protolist);
    print Data::Dumper->Dump([$rByP], [qw(rByP)])
	    if ($verbose > 5);

    print results2string(\@hostlist, \@protolist, $rByP);
}


=head1 SUBROUTINES

=head2 ping_list_by_proto(\@hostlist, \@protolist)

Use Net::Ping or LWP::UserAgent to test a list of hosts with list of proto.
Returns reference to a hash with ping results.

=cut

sub ping_list_by_proto
{

    my $results_by_proto;

    my ($hl, $pl) = @_;
    croak" missing host list " if (! $hl);
    croak" missing proto list " if (! $pl);

    for my $proto (@$pl) {

	print STDERR "# proto=$proto\n" if ($verbose > 3);

	# LWP
	if (($proto eq "http") || ($proto eq "https")) {

	    for my $host (@$hl) {

		my $url = $proto . "://" . $host;
		my $ua = LWP::UserAgent->new;
		$ua->timeout(5); # 5 sec timeout
		my $req = HTTP::Request->new(GET => $url );
		$req->header('Accept' => 'text/html');

		my $res = $ua->request($req);


		if ($res->is_success) {
		    print STDERR "$host at $url sucessful.\n"
		    	if ($verbose > 3);
		    $results_by_proto->{$host}->{$proto}++;
		} else {
		    print STDERR "$host at $url not successful: "
			. $res->status_line . ".\n" 
			if ($verbose > 3);
		    $results_by_proto->{$host}->{$proto}=0;
		}
	    }

	# ping
	} elsif (($proto eq "icmp") ||
		 ($proto eq "udp") ||
		 ($proto eq "tcp") ||
		 ($proto eq "external") ||
		 ($proto eq "syn") ||
		 ($proto eq "stream") ) {

	    my $p = Net::Ping->new($proto);
	    for my $host (@$hl) {
		if ($p->ping($host, 5)) { # 5 = 5 sec
		    print STDERR "$host responds to $proto.\n"
		    	if ($verbose > 3);
		    $results_by_proto->{$host}->{$proto}++;
		} else {
		    print STDERR "$host does not respond to $proto.\n"
		    	if ($verbose > 3);
		    $results_by_proto->{$host}->{$proto}=0;
		}
	    }
	    $p->close();

	} else {
	    croak "Unimplemented protocol $proto";
	}
    }

    return $results_by_proto;

}

=head2 results2string(\@hostlist, \@protolist, $hashref)

take a reference to a nested hash of results by host by proto and
make a nice string out of it. Returns a string to print with results.

=cut

sub results2string
{
    my ($hl, $pl, $results_by_proto) = @_;
    croak" empty results - cannot format" if (! $results_by_proto);

    # print a table with results - sort by hostname
    my $s = sprintf("%-20.20s  ", uc("host"));
    for my $proto (@$pl) {
	$s .= "	" . uc($proto);
    }
    $s .= "\n";

    for my $host (sort @$hl) {
	$s .= sprintf("%-20.20s  ", $host);
	for my $proto (@$pl) {
	    if ($results_by_proto->{$host}->{$proto}) {
		$s .= "	yes";
	    } else {
		$s .= "	NO";
	    }
	}
	$s .= "\n";
    }
    return $s;
}
