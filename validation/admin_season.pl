use Tools;

{
    fields  => [ qw/id name description startdate enddate isactive netvisorid_product/],

    filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
                 name          => filter('lc', 'ucfirst'),
               ],

    checks  => [ [qw/name startdate enddate isactive netvisorid_product/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
                 startdate => sub {
                                       my ($value, $params) = @_;

                                       if(not defined($value) or $value eq '') { return undef;  }
                                       if( defined(to_epoch($value)) ) {
                                            $params->{'startdate'} = to_epoch($value);
                                            return undef;
                                        }
                                        return 'Päivämäärä tulee syöttää muodossa pp.kk.vvvv';
                                  },
                 enddate   => sub {
                                       my ($value, $params) = @_;

                                       if(not defined($value) or $value eq '') { return undef;  }
                                       if( defined(to_epoch($value)) ) {
                                           $params->{'enddate'} = to_epoch($value);
                                           return undef;
                                       }
                                       return 'Päivämäärä tulee syöttää muodossa pp.kk.vvvv';
                                  },
               ],
}
