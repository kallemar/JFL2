package JFLRoster;
package JFLRoster;
use Dancer ':syntax';
use Dancer::Plugin::ValidateTiny;
use Dancer::Plugin::Database;
use Dancer::Plugin::Auth::Extensible;
use POSIX;
use Data::Dumper;

prefix '/roster';

sub activeseasonid {
    my $db = database();
    my $id = $db->quick_lookup(
                    'season',
                    { isactive => '1' },
                    'id'
                );
    return $id;
};

get '/' => sub {
      redirect '/roster/suburban/index';
};

#=======================================================================
# route        /roster/set_season
# state        private
# URL          GET localhost:3000/roster/report
#-----------------------------------------------------------------------
# description  sets the seasons for roster interface
#=======================================================================
post '/set_season' => require_any_role [qw(admin contact)] => sub {
   my $params = params;
   session seasonid => $params->{'changeSeason'};
   return redirect '/roster';    
};


# SUBURBAN ROUTES
get '/suburban/index' => require_any_role [qw(admin coach contact)] => sub {
	my $sth = database->prepare(
			'SELECT id,name,description,(SELECT count(id) FROM player WHERE suburbanid=suburban.id) as player_count FROM suburban WHERE seasonid=? ORDER BY name'
    );
    $sth->execute(session('seasonid'));

	my @suburbans;
	while(my $row = $sth->fetchrow_hashref) {
		my $id = $row->{'id'};
		my $sth2 = database->prepare(
			'SELECT contactid,suburbanid,contact.firstname,contact.lastname FROM contact_suburban,contact WHERE suburbanid=? AND contactid=contact.id'
		);
		$sth2->execute($id);
		
		my @contacts;
		while(my $row2 = $sth2->fetchrow_hashref) {
			push @contacts, $row2;
		}
		$row->{'contacts'} = \@contacts;
		push @suburbans, $row;
	}
    template 'roster_suburban_index', { suburbans => \@suburbans} , { layout => 'bootstrap.tt' };
};

get '/suburban/:id' => require_any_role [qw(admin coach contact)] => sub {
    my $params = params;
    my $id = $params->{'id'};
    my $sth;

	$sth = database->prepare('SELECT id,name,description,(SELECT count(id) FROM player WHERE suburbanid=suburban.id) as player_count FROM suburban WHERE id=?');
	$sth->execute($id);	
	my $suburban;# = $sth->fetchrow_hashref;


	$sth = database->prepare(
		'SELECT id,name FROM team WHERE suburbanid=? ORDER BY name'
	);
    $sth->execute($id);
	
	my @teams;
	while(my $row2 = $sth->fetchrow_hashref) {
		push @teams, $row2;
	}
	$suburban->{'teams'} = \@teams;
	#push $suburban, $row;

	debug Dumper($suburban);
    template 'roster_team_index', { suburban => $suburban }, { layout => 'bootstrap.tt' };
};

# TEAM ROUTES
get '/team/:id' => require_any_role [qw(admin coach contact)] => sub {

    my $params = params;
    my $id = $params->{'id'};
    my $sth;
    
    #read teams
    if ($id eq '0') {
		$sth = database->prepare('SELECT id,firstname,lastname,birthyear,email,phone,paid,number,invoiced FROM player WHERE teamid=null ORDER BY lastname,firstname');
		$sth->execute();
	} elsif ($id eq '*') {
		$sth = database->prepare('SELECT id,firstname,lastname,birthyear,email,phone,paid,number,invoiced FROM player WHERE suburbanid=1 ORDER BY lastname,firstname');
		$sth->execute();
	} else {
		$sth = database->prepare('SELECT id,firstname,lastname,birthyear,email,phone,paid,number,invoiced FROM player WHERE teamid=? ORDER BY lastname,firstname');
		$sth->execute($id);	
	}

	#read players
	my @players;
	while(my $row = $sth->fetchrow_hashref) {
		push @players, $row;
	}

	#read contacts
	$sth = database->prepare(
			'SELECT * FROM contact WHERE id=(SELECT contactid FROM contact_suburban WHERE suburbanid=(SELECT suburbanid FROM team WHERE id=?))'
    );
    $sth->execute($id);
	my @contacts;
	while(my $row = $sth->fetchrow_hashref) {
		push @contacts, $row;
	}
	
	#read coaches
	$sth = database->prepare(
			'SELECT * FROM coach WHERE teamid=? ORDER BY lastname,firstname'
    );
    $sth->execute($id);
	my @coaches;
	while(my $row = $sth->fetchrow_hashref) {
		push @coaches, $row;
	}
	
	template 'roster_team_view', 
			{
				players => \@players,
				coaches => \@coaches,
				contacts => \@contacts,
			},
			{
				layout => 'bootstrap.tt' 
			};
};

### PLAYER ROUTES ###
get '/view/player/:id' => require_any_role [qw(admin coach contact)] => sub {
    my $params = params;
    my $id = $params->{'id'};
	my $sth;
	
	#get player data
	$sth = database->prepare(
			'SELECT * FROM player WHERE id=?'
    );
    $sth->execute($id);
	my $player = $sth->fetchrow_hashref;

	#get parent data
	$sth = database->prepare(
			'select * from parent where id=(select parentid from player_parent where playerid=?)'
    );
    $sth->execute($id);
	my $parent = $sth->fetchrow_hashref;

	template 'roster_player_details', 
			{
				player => $player,
				parent => $parent,
			},
			{
				layout => 'bootstrap.tt' 
			};

};

get '/edit/player/:id' => require_any_role [qw(admin coach contact)] => sub {
	my $db = database();
    my $params = params;
    my $id = $params->{'id'};
    my $player;
    #FIXME = $db->player->read($id);

    template 'roster_player_edit', {
                                       player    => $player,
                                   },
                                   {
                                       layout => undef,
                                   };
};

post '/edit/player' => sub {
	my $db = database();
    my $params = params;
    my $data = validator($params, 'roster_player_edit.pl');
};


get '/rekisteriseloste'=> require_login sub {
	my $db = database();
    my $data = '';
    template 'roster_rekisteriseloste', $data, { layout => 'bootstrap.tt' };
};

get '/myprofile' => require_login sub {
	my $db = database();
    my $data;
};

get '/changepassword' => require_login sub {
	my $db = database();
    my $user = logged_in_user;
    my $data->{'user'} = $user;
    template 'roster_changepassword', $data, { layout => 'bootstrap.tt' };
};

post '/changepassword' => require_login sub {
	my $db = database();
    my $params = params;
    my $data = validator($params, 'roster_changepassword.pl');

};

get '/export/players/:id' => require_login sub {
	my $db = database();
    my $params = params;
    my $id = $params->{'id'};
    my $players = $db->player->read({
                                -and => {
                                    suburbanid => $id,
                                    seasonid => activeseasonid(),
                                   }})->collection;
    my $data;
    my $csv=Text::CSV->new();

    my $header = 'Numero'       . ',';
    $header .= 'etunimi'         . ',';
    $header .= 'sukunimi'        . ',';
    $header .= 'syntymävuosi'    . ',';
    $header .= 'osoite'          . ',';
    $header .= 'postinumero'     . ',';
    $header .= 'postitoimipaikka'. ',';
    $header .= 'puhelin'         . ',';
    $header .= 'sähköposti'      . ',';
    $header .= 'kaupunginosa'    . ',';
    $header .= 'joukkue'         . ',';
    $header .= 'laskutettu'      . ',';
    $header .= 'maksettu'        . ',';
    $header .= 'peruttu'         . ',';
    # parent data
    $header .= 'suhde pelaajaan' . ',';
    $header .= 'etunimi'         . ',';
    $header .= 'sukunimi'        . ',';
    $header .= 'puhelin'         . ',';
    $header .= 'sähköposti'      . ',';
    $header .= 'kiinnostus'      . ',';
    $header .= 'muuta'           . ',';
    $header .= "\n";

    $data = $header;
    foreach my $player (@{ $players }) {
        $player->{'team'}     =
            $db->team->read( { id => $player->{'teamid'} } )->current->{name};
        $player->{'suburban'} =
            $db->suburban->read( { id => $player->{'suburbanid'} } )->current->{name};

       my $parentid =
           $db->player_parent->read({ playerid => $player->{'id'} })->current->{'parentid'};
       if( defined($parentid) ) {
            $player->{'parent'} = $db->parent->read($parentid)->current;
       }

        my $invoiced  = $player->{invoiced}  ne '' ? DateTime->from_epoch(epoch => $player->{invoiced} )->dmy('.')  : '';
        my $paid      = $player->{paid}      ne '' ? DateTime->from_epoch(epoch => $player->{paid} )->dmy('.')      : '';
        my $cancelled = $player->{cancelled} ne '' ? DateTime->from_epoch(epoch => $player->{cancelled} )->dmy('.') : '';

        my @columns;
        push(@columns, $player->{number});
        push(@columns, $player->{firstname});
        push(@columns, $player->{lastname});
        push(@columns, $player->{birthyear});
        push(@columns, $player->{street});
        push(@columns, $player->{zip});
        push(@columns, $player->{city});
        push(@columns, $player->{phone});
        push(@columns, $player->{email});
        push(@columns, $player->{suburban});
        push(@columns, $player->{team});
        push(@columns, $invoiced);
        push(@columns, $paid);
        push(@columns, $cancelled);

        # parent data
        push(@columns, $player->{parent}->{relation});
        push(@columns, $player->{parent}->{firstname});
        push(@columns, $player->{parent}->{lastname});
        push(@columns, $player->{parent}->{phone});
        push(@columns, $player->{parent}->{email});
        push(@columns, $player->{parent}->{interest});
        push(@columns, $player->{parent}->{comment});

        my $status = $csv->combine(@columns);
        $data .= $csv->string() . "\n";
    }
   return send_file( \$data, content_type => 'text/csv',
                             filename     => 'pelaajat.csv' );
};



true;
