{
    fields  => [ qw/number cancelled/],

    filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
               ],

    checks  => [ cancelled      => sub {
                                        my ($value, $params) = @_;
                            
                                        if(not defined($value) or $value eq '') { return undef;  }
                                        if( defined(to_epoch($value)) ) {
                                            $params->{'cancelled'} = to_epoch($value);
                                            return undef;
                                        }
                                        return 'Päivämäärä tulee syöttää muodossa pp.kk.vvvv';
                                      },
               ],
}
