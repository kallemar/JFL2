#=======================================================================
# package      Pager123
# state        public
# description  object interface for 123 pager
#=======================================================================
package Pager123;

use Dancer;
use POSIX;

#=======================================================================
# function     new
# state        public
#-----------------------------------------------------------------------
# syntax       $Object = ABCPager->new( table  => 'table',
#                                       column => 'column');
#-----------------------------------------------------------------------
# description  Constructor for ABCPager object.
#
#-----------------------------------------------------------------------
# input        table | table name which contains rows | string
# input        column | column name for the paging | string
# return       object | ABCPager object | object
#=======================================================================
sub new {
    my ($class, $hArgs) = @_;

    bless {
		'_current'        => $hArgs->{'current'},
		'_totalcount'     => $hArgs->{'totalcount'},
        '_items_per_page' => config->{pager_items_per_page},
        '_pages'          => ceil($hArgs->{'totalcount'} /
                                  config->{pager_items_per_page}),
        '_max_pages'      => config->{pager_max_pages},
        '_route'          => $hArgs->{'route'},
        '_search'         => $hArgs->{'search'},
    }, $class;
}

sub items_per_page {
    my ( $self ) = @_;

    return $self->{'_items_per_page'};
}

sub max_pages {
    my ( $self ) = @_;

    return $self->{'_max_pages'};
}

sub pages {
    my ( $self ) = @_;

    return $self->{'_pages'};
}

sub current {
    my ( $self ) = @_;

    return $self->{'_current'};
}

sub route {
    my ( $self ) = @_;

    return $self->{'_route'};
}

sub search {
    my ( $self ) = @_;

    return $self->{'_search'};
}

sub last {
    my ( $self ) = @_;

    return $self->{'_pages'};
}
1;
