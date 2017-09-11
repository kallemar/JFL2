use Dancer ':syntax';
use Dancer::Plugin::ORMesque;

{
    fields  => [ qw/firstname lastname street zip city phone email password/],

    filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
                 firstname     => filter('lc', 'ucfirst'),
                 lastname      => filter('lc', 'ucfirst'),
                 address       => filter('ucfirst'),
                 city          => filter('lc', 'ucfirst'),
                 email         => filter('lc'),
               ],

    checks  => [ [qw/firstname lastname  phone email password/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
                 email    => sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
               ],
}
