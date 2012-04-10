#
#===============================================================================
#
#         FILE: Utils.pm
#
#  DESCRIPTION: Utilities
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (),
#      COMPANY:
#      VERSION: 1.0
#      CREATED: 02/12/2011 23:09:11
#     REVISION: ---
#===============================================================================

package ScosDecom::Utils;

use warnings;
use strict;

=head1 NAME

Ccsds - Module containing some utilities

=cut

#Simple Global Accumulator
my $log;

sub clrlog { $log="" }
sub mlog { $log .= shift if defined($_[0]); $log; }

#Binary to decimal converter
sub bin2dec { return unpack( "N", pack( "B32", substr( "0" x 32 . shift, -32 ) ) ); }

#extract bitstream from raw
#in: off and len are in bits, sign = 1 for signed values (2s complement)
#out: Undef if out of bound, Big endian value otherwise
sub extract_bitstream {
    my ( $raw, $off, $len, $sign ) = @_;

    #inclusive offset
    my $off2i = $off + $len - 1;
    my ( $from, $to ) = map { int( $_ / 8 ) } ( $off, $off2i );
    my ( $off_l, $off2_r ) = map { $_ % 8 } ( $off, $off2i );
    my $n = $to - $from + 1;
    if ( length($raw) < ($from + $n) ) {
        use Ccsds::Utils "hdump";
        mlog "Trying to extract outside packet! raw is:\n". hdump($raw) . "\n";
        mlog "off=$off,len=$len,offbytes=" . $off/8 . "\n";
        return undef;
    }
    my $val = substr( $raw, $from, $n );

    #Trim left/right bits
    my $mask_l = pack( "b8", "1" x ( 8 - $off_l ) );
    my $mask_r = pack( "B8", "1" x ( $off2_r + 1 ) );
    substr( $val, 0,  1 ) &= $mask_l ;
    substr( $val, -1, 1 ) &= $mask_r ;
    my $num = 0;
    for ( my $i = 0 ; $i < $n ; $i++ ) {

        $num = $num * 256 + unpack( 'C', substr( $val, $i, 1 ) );
    }

    #shift to right
    $num = $num >> 7 - $off2_r ;
    #2's complement if data to return is signed
    $num=-(2**$len-$num)
            if $sign and ($num&1<<$len-1);
    return $num;
}

sub ScosType2BitLen {
    my ( $ptc, $pfc ) = @_;
    my $len;

    if ( $ptc == 2 ) {
        $len = $pfc;
    }
    elsif ( $ptc == 3 or $ptc == 4 ) {
        if ( $pfc == 13 ) {
            $len = 24;
        }
        elsif ( $pfc == 14 ) {
            $len = 32;
        }
        elsif ( $pfc <= 12 ) {
            $len = $pfc + 4;
        }
        else {
            die "ptc:$ptc,pfc:$pfc not supported by Scos 2000\n";
        }
    }
    elsif ( $ptc == 5 and $pfc == 1) {
        $len=32;
    }
    elsif ( $ptc == 5 and $pfc == 2) {
        $len=64;
    }
    elsif ( $ptc == 7 ) {
        $len = $pfc;
    }
    elsif ( $ptc == 9 and $pfc == 18 ) {
        $len=56;
    }
    else {
        die "ptc:$ptc,pfc:$pfc not done\n";
    }
    $len;
}

sub tm_get_type_stype {
    my ($tm) = @_;
    return unless ( $tm->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'} );
    my $sh = $tm->{'Packet Data Field'}->{'TMSourceSecondaryHeader'};
    return [ $sh->{'Service Type'}, $sh->{'Service Subtype'} ];
}

sub tc_get_type_stype {
    my ($tc) = @_;
    return unless ( $tc->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'} );
    my $sh = $tc->{'Packet Data Field'}->{'TCSourceSecondaryHeader'};
    return [ $sh->{'Service Type'}, $sh->{'Service Subtype'} ];
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(clrlog mlog extract_bitstream bin2dec ScosType2BitLen tm_get_type_stype tc_get_type_stype);

=head1 SYNOPSIS

This library adds some helpers for working on bit bytes fields among other stuffs

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<teebeenator at gmail.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ScosDecom::Utils


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;

