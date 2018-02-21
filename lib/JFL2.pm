package JFL2;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::ValidateTiny;
use Dancer::Plugin::Email;
use Dancer::Plugin::ORMesque;
use Data::Dumper;

#--session must contain seasonid. If it isn't defined the active season
#--will be used.
hook before => sub {
    my $seasonid = db->season->read({ isactive => 1 })->current->{'id'};

    if( not session('seasonid') ) {
        session seasonid => $seasonid;
    }
    #-- this is needed for dynamic change season feature
    session seasons => db->season->read()->collection;
};

#-- admin interface
use JFLAdmin;

#-- roster inferface
use JFLRoster;

#-- REST interface for team data
use JFLRest;

#-- Export interface
use JFLExport;

#-- Interface to Netvisor
use JFLNetvisor;

our $VERSION = '1.2';

prefix undef;

#=======================================================================
# route        /
# state        public
# URL          GET localhost:3000/
#-----------------------------------------------------------------------
# description  Default redirect to to player registration form
#-----------------------------------------------------------------------
get '/' => sub {
	my @seasons = database->quick_select(
									'season',
									{
										isactive => 1
									}
									);

	my $data->{'seasons'} = \@seasons;
	
	template 'publichome', $data, { layout => "bootstrap_nomenu.tt" };
};

#=======================================================================
# route        /player/:id
# state        public
# URL          GET localhost:3000/player/:id
#-----------------------------------------------------------------------
# description  Opens / handles player registration form actions. Saves
#              posted data to the session after form validation.
#-----------------------------------------------------------------------
# TODO: suburbanin voi disabloida, jos menee esim. täyteen
# TODO: Pelipaitakysymyksen normalisointi
# TODO: väärälle seasonille rekisteröitymisen estäminen
get '/player/:id' => sub {
	my $params = params;
	my $data;
	my $seasonid = $params->{'id'};
	
	my $season = database->quick_select(
							'season',
							{
								id  => $seasonid
                            });
	# get suburbans 
	my @suburbans = database->quick_select(
							'suburban',
							{
								seasonid  => $seasonid,
								isvisible => 1,
                            });
							
	# get options for this season	
	#my $sth = database->prepare(
	#	'select optionid from season_option where seasonid=?',
	#);
	#$sth->execute($seasonid);
	#my $option = $sth->fetchrow_hashref;
	my $optionid = 1;
	my @optionschoices = database->quick_select(
							'optionchoice',
							{
								optionid  => $optionid,
                            }
						);    
        
	
	
		
	if( session->{'player'} ) {
	   $data = session->{'player'};
	}

	$data->{'season'} = $season;
	$data->{'suburbans'} = \@suburbans;
	$data->{'optionchoices'} = \@optionschoices;
#	debug Dumper(\@suburbans);
	debug Dumper($data);
	template 'player_registration2', $data, { layout => "bootstrap_nomenu.tt" };
};

post '/player' => sub {
	my $params = params;
	# Validating params with rule file
	my $data = validator($params, 'player2.pl');
	debug Dumper($data);

	if($data->{valid}) {
		session parent => $data;
		return redirect '/info';
	}	
};


#=======================================================================
# route        /done
# state        public
# URL          GET localhost:3000/info
#-----------------------------------------------------------------------
# description  Final route in registration flow. Saves all the data
#              to database and shows confirmation page.
#-----------------------------------------------------------------------
get '/done' => sub {
};


post '/check' => sub {
	my $params = params;
	# Validating params with rule file
	my $data = validator($params, 'check.pl');
	
	sendmail_check_personal_info( $data->{'result'}->{'email'} );

	return redirect '/';
};

sub sendmail_check_personal_info {
    my $sendto = shift;
	debug $sendto;
	
	email {
		from    => 'toimisto@tpv.fi',
		to      => $sendto,
		subject => 'Futisklubin omien tietojen tarkistaminen',
		body    => template('check_mail.tt',
							{ data => $sendto },
							{ layout => 'empty.tt' }),
		type    => 'html', # can be 'html' or 'plain'
		# Optional extra headers
		headers => {
			"X-Mailer"          => 'This fine Dancer application',
			"X-Accept-Language" => 'fi',
		},
	};
};


#-- login, logout and other auth procedures
# NOTE: For some reasons this doesn't work on file header (Timo)
use AuthManager;

true;
