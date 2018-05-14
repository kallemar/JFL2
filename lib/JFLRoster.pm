package JFLRoster;
use Dancer ':syntax';
use Dancer::Plugin::ValidateTiny;
use Dancer::Plugin::ORMesque;
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


get '/suburban/index' => require_any_role [qw(admin coach contact)] => sub {
   my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') },
                             ['name'])
                      ->collection;

   #my $suburbans = db->suburban->read({ seasonid => activeseasonid() },
    #                         ['name'])
     #                 ->collection;

    #--Contacts
    foreach my $sub (@{ $suburbans }) {
        my $contactids = db->contact_suburban
                        ->read( { suburbanid => $sub->{'id'} } )
                        ->collection;

        my @contacts;
        foreach my $csid (@{ $contactids })  {
            push(@contacts, db->contact
                              ->read($csid->{'contactid'})
                              ->current);
        }
        $sub->{'contacts'} = \@contacts;
        $sub->{'players'} = db->player->read({suburbanid => $sub->{'id'}})->count;
    }

    template 'roster_suburban_index', {suburbans => $suburbans}, { layout => 'bootstrap.tt' };
};

get '/view/player/:id' => require_any_role [qw(admin coach contact)] => sub {
    my $params = params;
    my $id = $params->{'id'};
    my $player = db->player->read($id)->current;
    my $parentid = db->player_parent
                     ->read({ playerid => $id })
                     ->current->{'parentid'};

    # update player data
    $player->{'suburban'} = db->suburban
                     ->read({ id => $player->{'suburbanid'} })
                     ->current->{'name'};
    if ($player->{'teamid'}) {
        $player->{'team'} = db->team
                     ->read({ id => $player->{'teamid'} })
                     ->current->{'name'};
    } else {
        $player->{'team'} = 'määrittämätön';
    }

    # set parent data
    my $parent;
    if(defined($parentid)) {
        $parent = db->parent->read($parentid)->current;
    }

    template 'roster_player_details', {
                                       player    => $player,
                                       parent    => $parent,
                                      },
                                      { layout => 'bootstrap.tt' };
};

get '/edit/player/:id' => require_any_role [qw(admin coach contact)] => sub {
    my $params = params;
    my $id = $params->{'id'};
    my $player = db->player->read($id);

    template 'roster_player_edit', {
                                       player    => $player,
                                   },
                                   {
                                       layout => undef,
                                   };
};

post '/edit/player' => sub {
    my $params = params;
    my $data = validator($params, 'roster_player_edit.pl');
    my $id = $data->{'result'}->{'id'};
    my $teamid = db->player->read($id)->teamid;

    if($data->{valid}) {
        # save updated values to players record
        my $number = $data->{'result'}->{'number'};
        db->player->update({
                               number => $number,
                           },
                           {
                               id => $id,
                           });

        # return back to team index
        return redirect '/roster/team/' . $teamid;

    } else {
        #non valid input -> return back to team index, no warning message
        return redirect '/roster/team/' . $teamid;
    };
};

get '/suburban/:id' => require_any_role [qw(admin coach contact)] => sub {
    my $id = params->{'id'};
    my $suburbans = db->suburban->read($id)->collection;

    #--Contacts
    foreach my $sub (@{ $suburbans }) {
        my $contactids = db->contact_suburban
                        ->read( { suburbanid => $sub->{'id'} } )
                        ->collection;

        my @contacts;
        foreach my $csid (@{ $contactids })  {
            push(@contacts, db->contact
                              ->read($csid->{'contactid'})
                              ->current);
        }

        my $teams = db->team
                        ->read( { suburbanid => $sub->{'id'} } )
                        ->collection;

        foreach my $team (@{ $teams }) {
            $team->{'players'} = db->player->read({
                                                   teamid    => $team->{'id'},
                                                   -or => [
                                                            cancelled => undef,
                                                            cancelled => ''
                                                           ]
                                                  })->count;
        }


        $sub->{'contacts'} = \@contacts;
        $sub->{'teams'} = $teams;
    };

    template 'roster_team_index', { suburbans => $suburbans }, { layout => 'bootstrap.tt' };
};

get '/team/:id' => require_any_role [qw(admin coach contact)] => sub {
	#TODO
	#- add 'deactivate' function for a player
	#- add 'edit' function for a player
	#- export email addresses function
	#- finetune player and coach data: what to display and what to not

	my $user = logged_in_user;
	my $params = params;
	my $id = $params->{'id'};
	my $players = '';
	my $coaches = '';
	my $team = '';
	my $suburban = '';
	my $parentid;

	#get players
	$players = db->player
				 ->read({ teamid => $id }, ['birthyear DESC', 'lastname'])
				 ->collection;

	#Get coaches
	$coaches = db->coach->read({ teamid => $id } )->collection;
	
	$team = db->team->read($id)->current;
	$suburban = db->suburban->read($team->{'suburbanid'})->current;

	#--Contacts
    my $contactids = db->contact_suburban
				->read( { suburbanid => $suburban->{'id'} } )
				->collection;
	my @contacts;
        foreach my $csid (@{ $contactids })  {
            push(@contacts, db->contact
                              ->read($csid->{'contactid'})
                              ->current);
     }
     $suburban->{'contacts'} = \@contacts;

     foreach my $player (@{ $players })  {
        #do the parent record have comments?
        $parentid = db->player_parent
                     ->read({ playerid => $player->{'id'} })
                     ->current->{'parentid'};
        $player->{'comment'} = db->parent->read($parentid)->current->{'comment'};
        $player->{'interest'} = db->parent->read($parentid)->current->{'interest'};

        # set T-shirt size
        my $shirtsizeid = $player->{'shirtsizeid'};
        my $shirtsize_name = '';
        if ($shirtsizeid > 0) {
            $shirtsize_name = db->shirtsizetable->read($shirtsizeid)->current->{'name'};
        } else {
            $shirtsize_name = '-';
        }
        $player->{'shirtsize_name'} = $shirtsize_name;
     }
     my $data->{'players'} = $players;

     $data->{'coaches'} = $coaches;
     $data->{'team'} = $team;
     $data->{'suburban'} = $suburban;

     #check if we can proceed: admin can always but coaches and contacts only when they listed for this team
     my $contacts = db->contact_suburban->read({'suburbanid' => $suburban->{'id'} })->collection;
     my $proceed = false;
     if (user_has_role('coach')) {
         foreach my $coach (@{ $data->{'coaches'} }) {
			if ($coach->{'id'} == $user->{'coachid'} ) {
	            $proceed = true;
            }
         }
     };

     if (user_has_role('contact')) {
         $proceed = true;
     };
     if (user_has_role('admin')) {
         $proceed = true;
     };
     if ($proceed) {
        template 'roster_team_view', $data, { layout => 'bootstrap.tt' };
     } else {
        redirect '/roster';
     };
};

get '/team-unset/:id' => require_any_role [qw(admin contact)] => sub {
     my $user = logged_in_user;
     my $params = params;
     my $id = $params->{'id'};
     my $suburban = db->suburban->read($id)->current;
     my $players = db->player ->read({
                                        suburbanid => $suburban->{'id'},
                                         -or => [
                                            teamid     => undef,
                                            teamid     => '' ]

  	                             }, ['birthyear DESC', 'lastname'])->collection;

     my $contacts = db->contact_suburban->read({'suburbanid' => $id })->collection;
     my $parentid;

     foreach my $player (@{ $players })  {
        #do the parent record have comments?
        $parentid = db->player_parent
                     ->read({ playerid => $player->{'id'} })
                     ->current->{'parentid'};
        $player->{'comment'} = db->parent->read($parentid)->current->{'comment'};
        $player->{'interest'} = db->parent->read($parentid)->current->{'interest'};
     }
     my $data->{'players'} = $players;

     #--Contacts
     my $contactids = db->contact_suburban
                        ->read( { suburbanid => $suburban->{'id'} } )
                        ->collection;
     my @contacts;
        foreach my $csid (@{ $contactids })  {
            push(@contacts, db->contact
                              ->read($csid->{'contactid'})
                              ->current);
     }
     $suburban->{'contacts'} = \@contacts;
     $data->{'suburban'} = $suburban;

     my $proceed = false;
     if (user_has_role('contact')) {
        $proceed = true;
     };

     if (user_has_role('admin')) {
          $proceed = true;
     };

     if ($proceed) {
        template 'roster_team_unset_view', $data, { layout => 'bootstrap.tt' };
     } else {
        redirect '/roster';
     };
};

get '/team-all/:id' => require_any_role [qw(admin contact)] => sub {
     my $user = logged_in_user;
     my $params = params;
     my $id = $params->{'id'};
     my $suburban = db->suburban->read($id)->current;
     my $players = db->player->read({'suburbanid' => $id }, ['birthyear DESC', 'lastname'])->collection;
     my $contacts = db->contact_suburban->read({'suburbanid' => $id })->collection;
     my $parentid;

     foreach my $player (@{ $players })  {
        #--Set team name into player record
        my $teamid = $player->{'teamid'};
        if ($teamid) {
           $player->{'team'} = db->team->read($player->{'teamid'})->current->{'name'};
        } else {
           $player->{'team'} = "(Määrittämätön)";
        }

        #do the parent record have comments?
        $parentid = db->player_parent
                     ->read({ playerid => $player->{'id'} })
                     ->current->{'parentid'};
        $player->{'comment'} = db->parent->read($parentid)->current->{'comment'};
        $player->{'interest'} = db->parent->read($parentid)->current->{'interest'};
     }
     my $data->{'players'} = $players;

     #--Coaches
     my $coaches = db->query('SELECT id as coachid,firstname,lastname,phone,email FROM coach WHERE suburbanid=' . $id)->hashes;
     $data->{'coaches'} = $coaches;

     #--Contacts
     my $contactids = db->contact_suburban
                        ->read( { suburbanid => $suburban->{'id'} } )
                        ->collection;
     my @contacts;
        foreach my $csid (@{ $contactids })  {
            push(@contacts, db->contact
                              ->read($csid->{'contactid'})
                              ->current);
     }
     $suburban->{'contacts'} = \@contacts;
     $data->{'suburban'} = $suburban;

     #--Determine should we show data or not
     my $proceed = false;
     if (user_has_role('contact')) {
        $proceed = true;
     };

     if (user_has_role('admin')) {
          $proceed = true;
     };

     if ($proceed) {
        template 'roster_team_all_view', $data, { layout => 'bootstrap.tt' };
     } else {
        redirect '/roster';
     };
};

get '/rekisteriseloste'=> require_login sub {
    my $data = '';
    template 'roster_rekisteriseloste', $data, { layout => 'bootstrap.tt' };
};

get '/myprofile' => require_login sub {
    my $data;
    if (user_has_role('admin')) {
        my $userdata = logged_in_user;
        my $data->{'user'} = $userdata;
        $data->{'user'}->{'role'} = 'pääkäyttäjä';
    }
    elsif (user_has_role('contact')) {
        my $id = logged_in_user->{'contactid'};
        my $userdata = db->contact->read($id)->current;
        $data->{'user'} = $userdata;
        # contact and coach has only email attribute whereas admin has username
        $data->{'user'}->{'username'} = $userdata->{'email'};
         $data->{'user'}->{'role'} = 'yhteyshenkilö';
    }
    elsif (user_has_role('coach')) {
        my $id = logged_in_user->{'coachid'};
        my $userdata = db->coach->read($id)->current;
        $data->{'user'} = $userdata;
        # contact and coach has only email attribute whereas admin has username
        $data->{'user'}->{'username'} = $userdata->{'email'};
        $data->{'user'}->{'role'} = 'ohjaaja';
    }
    my $flash;

    if (session('success_msg')) {
        $flash->{'success'} = session('success_msg');
        session success_msg => '';
    }
    $data->{'flash'} = $flash;

    template 'roster_myprofile', $data, { layout => 'bootstrap.tt' };
};

get '/changepassword' => require_login sub {
    my $user = logged_in_user;
    my $data->{'user'} = $user;
    template 'roster_changepassword', $data, { layout => 'bootstrap.tt' };
};

post '/changepassword' => require_login sub {
    my $params = params;
    my $data = validator($params, 'roster_changepassword.pl');

    if($data->{valid}) {
        #-- create password hash to be saved to database
        my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
        $csh->add($data->{'result'}->{'password'});
        my $salted = $csh->generate;

        # save the new password to user's record
        db->users->update({
                               password => $salted,
                           },
                           {
                               id => logged_in_user->{'id'}
                           });

        # set the success message and redirect to user profile page
        session success_msg => 'Salasana vaihdettu onnistuneesti';
        return redirect '/roster/myprofile';

    } else {
       my $flash->{'error'} = $data->{'result'}->{'err_password_confirm'};
       template 'roster_changepassword', {  data => $data,
                                            flash => $flash,
                                            valid     => 0 },
                                        { layout => 'bootstrap.tt' };
    };
};

get '/export/players/:id' => require_login sub {
    my $params = params;
    my $id = $params->{'id'};
    my $players = db->player->read({
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
            db->team->read( { id => $player->{'teamid'} } )->current->{name};
        $player->{'suburban'} =
            db->suburban->read( { id => $player->{'suburbanid'} } )->current->{name};

       my $parentid =
           db->player_parent->read({ playerid => $player->{'id'} })->current->{'parentid'};
       if( defined($parentid) ) {
            $player->{'parent'} = db->parent->read($parentid)->current;
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
