{
    fields  => [ qw/id name contactid description isvisible/],

    filters => [ # Remove spaces from all
                 qr/.+/ => filter(qw/trim strip/),
               ],

    checks  => [ [qw/name contactid/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
               ],
}
