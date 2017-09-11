use Hetu;
use Tools;

{
    fields  => [ qw/id firstname lastname hetu street zip city phone email suburbanid teamid sex invoiced shirtsizeid wantstoplayingirlteam paid cancelled
                    parent_firstname parent_lastname parent_phone parent_email parent_relation parent_interest parent_comment isinvoice/],

    filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
                 firstname     => filter('lc', 'ucfirst'),
                 lastname      => filter('lc', 'ucfirst'),
                 hetu          => filter('uc'),
                 address       => filter('ucfirst'),
                 city          => filter('lc', 'ucfirst'),
                 email         => filter('lc'),
                 email_confirm => filter('lc'),
               ],

    checks  => [ [qw/firstname lastname hetu street zip suburban city phone email suburbanid parent_firstname parent_lastname parent_phone parent_email/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
                 city          => is_long_at_most( 40, 'Liian pitkä kaupungin nimi' ),
                 zip_code      => is_long_at_least( 5, 'Virheellinen postinumero' ),
                 email         => sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
                 hetu          => sub {
                                         my ( $value, $params ) = @_;
                                         my $Hetu = Hetu->new( { hetu => $value } );
                                         return $Hetu->isValid ? undef : 'Viheellinen henkil&ouml;tunnus!';
                                      },
                 invoiced      => sub {
                                        my ($value, $params) = @_;
                                        #debug $params;

                                        if(not defined($value) or $value eq '') { return undef;  }
                                        if( defined(to_epoch($value)) ) {
                                            $params->{'invoiced'} = to_epoch($value);
                                            return undef;
                                        }
                                        return 'Päivämäärä tulee syöttää muodossa pp.kk.vvvv';
                                      },
                paid           => sub {
                                        my ($value, $params) = @_;
                                        #debug $params;

                                        if(not defined($value) or $value eq '') { return undef;  }
                                        if( defined(to_epoch($value)) ) {
                                            $params->{'paid'} = to_epoch($value);
                                            return undef;
                                        }
                                        return 'Päivämäärä tulee syöttää muodossa pp.kk.vvvv';
                                      },
                cancelled      => sub {
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
