use Dancer ':syntax';
use Dancer::Plugin::ORMesque;

{
    fields  => [ qw/id firstname lastname street zip city phone email password suburbanid teamid/],

    filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
                 firstname     => filter('lc', 'ucfirst'),
                 lastname      => filter('lc', 'ucfirst'),
                 address       => filter('ucfirst'),
                 city          => filter('lc', 'ucfirst'),
                 email         => filter('lc'),
               ],

    checks  => [ [qw/firstname lastname  phone email password suburbanid teamid/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
                 city          => is_long_at_most( 40, 'Liian pitkä kaupungin nimi' ),
                 zip_code      => is_long_at_least( 5, 'Virheellinen postinumero' ),
                 email         => sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
               ],
}
