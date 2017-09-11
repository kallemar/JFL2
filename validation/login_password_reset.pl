{
    fields  => [ qw/password password_confirm/],

    filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
               ],

    checks  => [ [qw/password/] => is_required("Anna uusi salasana!"),
                 password_confirm => is_equal('password', 'Salasanat eiv&auml;t t&auml;sm&auml;&auml;!'),
               ],
}
