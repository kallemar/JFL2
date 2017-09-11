{
    fields  => [ qw/email/],

    filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
               ],

    checks  => [ [qw/email/] => is_required("Sähköpostiosoite on pakollinen!"),
               ],
}
