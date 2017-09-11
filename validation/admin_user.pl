{
    fields  => [ qw/username password firstname lastname  phone role_id/],

    filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
                 firstname     => filter('lc', 'ucfirst'),
                 lastname      => filter('lc', 'ucfirst'),
                 email         => filter('lc'),
               ],

    checks  => [ [qw/username password firstname lastname phone/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
                 username => sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
               ],
}
