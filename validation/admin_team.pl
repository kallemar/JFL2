{
    fields  => [ qw/id name description suburban/],

    filters => [ # Remove spaces from all
                 qr/.+/ => filter(qw/trim strip/),
               ],

    checks  => [ [qw/name suburban/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
               ],
}
