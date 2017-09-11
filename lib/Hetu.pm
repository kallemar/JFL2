#========================================================================================
# package      Hetu
# state        public
# description  object interface for HETU validation and parsing.
#========================================================================================
package Hetu;

use strict;
use warnings FATAL => 'all';
#use Date::Pcalc qw(check_date);
use DateTime;

#========================================================================================
# function     new
# state        public
#----------------------------------------------------------------------------------------
# syntax       $Object = Hetu->new( {hetu => "010101-123A"} );
#----------------------------------------------------------------------------------------
# description  Constructor for Hetu object.
#
#----------------------------------------------------------------------------------------
# input        $hetu | hetu as string in format ddmmyy-nnna| object
# return       $Hetu | returns Hetu object | object
#========================================================================================
sub new {
    my ($class, $arg_ref) = @_;
    my $self = {};

    $self->{'hetu'} = $arg_ref->{'hetu'},
    bless $self, $class;

    $self->{'isvalid'} = $self->_initialize;
    return $self;
}

sub _checkdate {
    my($self) = @_;
    my $v = $self->{'year'};

    $v+=1800 if $self->{'century'} eq '+';
    $v+=1900 if $self->{'century'} eq '-';
    $v+=2000 if $self->{'century'} eq 'A';


    $self->{'birthyear'} = $v;
	my $dt = eval { 
		DateTime->new(
		    year   => $v,
		    month  => $self->{'month'}, 
		   day    => $self->{'day'}
	    )
	};
	
	if( defined $dt ) {
		return 1;
	} 
	else {
		return 0;
	}
    #return check_date($v, $self->{'month'}, $self->{'day'} );
}

sub _checksum {
    my ($self) = @_;
    my @checksum = ('0'..'9','A'..'F','H','J'..'N','P','R'..'Y');
    my $check    = $checksum["$self->{'day'}$self->{'month'}$self->{'year'}$self->{'id'}" % scalar @checksum];
    return 1 if $check eq $self->{'check'};
    return 0;
}
sub _initialize {
    my ($self) = @_;

    my $hetu=uc $self->{'hetu'};
    if($hetu=~/^(\d{2})(\d{2})(\d{2})([+-A])(\d{3})([0-9A-FHJ-NPR-Y])$/) {
        my ($p,$k,$v,$vs,$y,$t)=($1,$2,$3,$4,$5,$6);
        # päivä, kuukausi, vuosi, vuosisata, yksilö, tarkistus

        $self->{'day'}     = $p;
        $self->{'month'}   = $k;
        $self->{'year'}    = $v;
        $self->{'century'} = $vs;
        $self->{'id'}      = $y;
        $self->{'check'}   = $t;

        return 1;
    }
    return 0;
}

sub hetu {
    my ($self) = @_;
    return $self->{'hetu'}
}

sub isValid {
    my ($self) = @_;

    if( $self->{'isvalid'} && $self->_checkdate && $self->_checksum) {
        return 1;
    }
    return 0;
}

sub sex {
    my ($self) = @_;
    return $self->{id} % 2+1;
}

sub year {
    my ($self) = @_;
    my $v = $self->{'year'};

    $v+=1800 if $self->{'century'} eq '+';
    $v+=1900 if $self->{'century'} eq '-';
    $v+=2000 if $self->{'century'} eq 'A';

    return $v;
}
1;


