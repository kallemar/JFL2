#=======================================================================
# package      PagerABC
# state        public
# description  object interface for ABC pager
#=======================================================================
package PagerABC;

use Dancer;
use Dancer::Plugin::ORMesque;

#=======================================================================
# function     new
# state        public
#-----------------------------------------------------------------------
# syntax       $Object = PagerABC->new( table  => 'table', 
#                                       column => 'column');
#-----------------------------------------------------------------------
# description  Constructor for PagerABC object.
#
#-----------------------------------------------------------------------
# input        table | table name which contains rows | string
# input        column | column name for the paging | string
# return       object | ABCPager object | object
#=======================================================================
sub new {
    my ($class, $hArgs) = @_;

    bless {
		'_current' => $hArgs->{'current'},
        '_table'   => $hArgs->{'table'},
        '_column'  => $hArgs->{'column'},
    }, $class;
}

sub list {
    my ( $self ) = @_;
    my $table = $self->{'_table'};
    my $db = db->$table;
    
    my $query = 'select upper(substr(' . 
                 $self->{'_column'} . 
                 ',1, 1)), count(1) from ' . 
                 $self->{'_table'} .
                 ' group by upper(substr(' . $self->{'_column'} . 
                 ',1,1))';
    #debug "ABCPager->list query: ", $query;
     
    my $names = $db->query($query)->arrays;

    #debug "ABCPager->list: ", $names;

    return $names;
}


sub current {
    my ( $self ) = @_;
    
    return $self->{'_current'};
}
1;
