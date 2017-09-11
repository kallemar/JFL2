{
    fields  => [ qw/id number/],

    filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
               ],
}
