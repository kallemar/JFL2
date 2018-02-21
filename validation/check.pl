use Hetu;

{
    fields  => [ qw/email/],

	filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
                 ],

	checks  => [ [qw/email/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
				email         	=> sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
			   ],
}
