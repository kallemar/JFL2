
{
    fields  => [ qw/player_firstname player_lastname player_birthdate player_hetu player_address player_zip player_suburban player_city player_phone player_shirtsizeid player_wantstoplayingirlteam player_email player_email_confirm accept_legal parent_firstname parent_lastname parent_phone parent_email parent_email_confirm/],

	filters => [ # Remove spaces from all
                 qr/.+/        => filter(qw/trim strip/),
                 player_firstname     => filter('lc', 'ucfirst'),
                 player_lastname      => filter('lc', 'ucfirst'),
                 player_hetu          => filter('uc'),
                 player_address       => filter('ucfirst'),
                 player_city          => filter('lc', 'ucfirst'),
                 player_email         => filter('lc'),
                 player_email_confirm => filter('lc'),
                 parent_firstname     => filter('lc', 'ucfirst'),
                 parent_lastname      => filter('lc', 'ucfirst'),
                 parent_address       => filter('ucfirst'),
                 parent_city          => filter('lc', 'ucfirst'),
                 parent_email         => filter('lc'),
                 parent_email_confirm => filter('lc'),
               ],

	checks  => [ [qw/player_firstname player_lastname player_address player_zip player_suburban player_city parent_firstname parent_lastname parent_phone parent_email parent_email_confirm/] => is_required("T&auml;yt&auml; kaikki pakolliset kent&auml;t!"),
					# phone shirtsizeid email email_confirm
					
                 [qw/accept_legal/] 	=> is_required("Tietoturvaseloste tulee lukea ensin ja merkitä luetuksi!"),
				player_city          	=> is_long_at_most( 40, 'Liian pitkä kaupungin nimi' ),
				parent_city				=> is_long_at_most( 40, 'Liian pitkä kaupungin nimi' ),
				player_zip		      	=> is_long_at_least( 5, 'Virheellinen postinumero' ),
				parent_zip		      	=> is_long_at_least( 5, 'Virheellinen postinumero' ),
				player_email         	=> sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
				player_email_confirm 	=> sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
				parent_email         	=> sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },
				parent_email_confirm 	=> sub { check_email($_[0], "Virheellinen sähköpostiosoite.") },

				player_email_confirm 	=> is_equal('player_email', 'Pelaajan s&auml;hk&ouml;postiosoitteen varmennus ep&auml;onnistui!'),
				parent_email_confirm 	=> is_equal('parent_email', 'Vanhemman s&auml;hk&ouml;postiosoitteen varmennus ep&auml;onnistui!'),    
               ],
}
