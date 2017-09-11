{
    fields => [qw/firstname lastname phone email email_confirm relation interest comment/],
    checks => [
        [qw/firstname lastname phone email email_confirm/] => is_required("Kenttä on pakollinen!"),
          email         => sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
          email_confirm => sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
          email_confirm => is_equal('email', 'S&auml;hk&ouml;postiosoitteen varmennus ep&auml;onnistui!'),
    ],
}
