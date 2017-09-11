use Hetu;

{
    fields  => [ qw/firstname lastname hetu address zip suburban city phone shirtsizeid wantstoplayingirlteam email email_confirm/],

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

    checks  => [ [qw/firstname lastname hetu address zip suburban city phone shirtsizeid email email_confirm/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
                 city          => is_long_at_most( 40, 'Liian pitkä kaupungin nimi' ),
                 zip_code      => is_long_at_least( 5, 'Virheellinen postinumero' ),
                 email         => sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
                 email_confirm => sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
                 email_confirm => is_equal('email', 'S&auml;hk&ouml;postiosoitteen varmennus ep&auml;onnistui!'),
                 hetu          => sub {
                                         my ( $value, $params ) = @_;
                                         my $Hetu = Hetu->new( { hetu => $value } );
                                         return $Hetu->isValid ? undef : 'Viheellinen henkil&ouml;tunnus!';
                                      },
                 suburban      => sub {
                                          my ( $value, $params ) = @_;
                                          return $value != 18 ? undef : 'Ryhm&auml; on t&auml;ynn&auml;, mutta voit kysy&auml; varasijaa s&auml;hk&ouml;postilla niina@marjamaki.net'; 
                                       
                                      }
               ],
}
