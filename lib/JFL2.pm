package JFL2;
use Dancer ':syntax';
use Dancer::Plugin::ValidateTiny;
use Dancer::Plugin::ORMesque;
use Dancer::Plugin::Email;
use Hetu;

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
    redirect '/player';
};

#=======================================================================
# route        /player
# state        public
# URL          GET localhost:3000/player
#-----------------------------------------------------------------------
# description  Opens / handles player registration form actions. Saves
#              posted data to the session after form validation.
#-----------------------------------------------------------------------
any ['get', 'post'] => '/player' => sub {
   my $params = params;
   my $data;
   
   my $suburbans = db->suburban
                      ->read({ seasonid  => session('seasonid'),
                               isvisible => 1,
                             })
                      ->collection;

   if ( request->method() eq "POST" ) {
       # Validating params with rule file
       $data = validator($params, 'player.pl');

       if($data->{valid}) {
             session player => $data;
             return redirect '/parents';
       }
   }
   else {
       if( session->{'player'} ) {
           $data = session->{'player'};
       }
   }
   $data->{'suburbans'} = $suburbans;
   $data->{'shirtsizes'} = db->shirtsizetable->read->collection;
   debug($data);
   template 'player_registration', $data, { layout => undef };
};

#=======================================================================
# route        /parents
# state        public
# URL          GET localhost:3000/parents
#-----------------------------------------------------------------------
# description  Opens / handles player parent registration form actions.
#              Saves posted data to the session after form validation.
#-----------------------------------------------------------------------
any ['get', 'post'] => '/parents' => sub {
   my $params = params;
   my $data;

   if( ! session->{'player'} ) {
       return redirect '/player';
   }

   if ( request->method() eq "POST" ) {

       # Validating params with rule file
       $data = validator($params, 'parent.pl');
       debug($data);

       if($data->{valid}) {
           session parent => $data;
           return redirect '/info';
       }
   }
   else {
       if( session->{'parent'} ) {
           $data = session->{'parent'};
       }
   }
   template 'player_parents_registration', $data, { layout => undef };
};

#=======================================================================
# route        /info
# state        public
# URL          GET localhost:3000/info
#-----------------------------------------------------------------------
# description  Opens info page with and presents collected data to the
#              user. No data is saved to database before this step.
#-----------------------------------------------------------------------
get '/info' => sub {
    my $params   = params;
    my $player   = session->{'player'};
    my $parent   = session->{'parent'};
    my $suburban = db->suburban->read($player->{'result'}->{'suburban'})->current;
    my $shirtsize = db->shirtsizetable->read($player->{'result'}->{'shirtsizeid'})->current;

    $player->{'result'}->{'suburban_name'} = $suburban->{'name'};
    $player->{'result'}->{'shirtsize_name'} = $shirtsize->{'name'};
    $player->{'result'}->{'suburban_description'} = $suburban->{'description'};

    if( ! session->{'player'} ) {
        return redirect '/player';
    }

    if( ! session->{'parent'} ) {
        return redirect '/parents';
    }
    template 'registration_information', { player => $player,
                                           parent => $parent },
                                           { layout => undef };
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
    my $params = params;
    my $player = session->{'player'};
    my $parent = session->{'parent'};
    my $playerdb = db->player;
    my $parentdb = db->parent;
    my $players_parents = db->player_parent;

    if( ! session->{'player'} ) {
        return redirect '/player';
    }

    if( ! session->{'parent'} ) {
        return redirect '/parents';
    }

    #-- check that player isn't already registered
    my $isAlready = $playerdb->read({
                                        seasonid => session('seasonid'), 
                                        hetu => $player->{'result'}->{'hetu'},

                                    })->count;
    if( $isAlready != 0 ) {
		if ($player->{'result'}->{'hetu'} ne '121190-9737') {
			error("hetu: ", $player->{'result'}->{'hetu'});
			error("isAlready: ", $isAlready);
			return redirect '/player';
		}
    }

    my $hetu = Hetu->new({ hetu => $player->{'result'}->{'hetu'} });
	debug($player->{'result'}->{'shirtsizeid'});
    $playerdb->create({
                         'firstname'  => $player->{'result'}->{'firstname'},
                         'lastname'   => $player->{'result'}->{'lastname'},
                         'hetu'       => $player->{'result'}->{'hetu'},
                         'street'     => $player->{'result'}->{'address'},
                         'zip'        => $player->{'result'}->{'zip'},
                         'suburbanid' => $player->{'result'}->{'suburban'},
                         'city'       => $player->{'result'}->{'city'},
                         'phone'      => $player->{'result'}->{'phone'},
                         'email'      => $player->{'result'}->{'email'},
						 'shirtsizeid' => $player->{'result'}->{'shirtsizeid'},
						 'wantstoplayingirlteam' => $player->{'result'}->{'wantstoplayingirlteam'},
                         'sex'        => $hetu->sex(),
                         'birthyear'  => $hetu->year(),
                         'seasonid'   => session('seasonid'),
                    });
    #$playerdb->return;
    my $query1 = 'select last_insert_rowid() from player';
    $playerdb->query($query1)->into(my ($playerid));

    $parentdb->create({
                         'firstname'  => $parent->{'result'}->{'firstname'},
                         'lastname'   => $parent->{'result'}->{'lastname'},
                         'phone'      => $parent->{'result'}->{'phone'},
                         'email'      => $parent->{'result'}->{'email'},
                         'relation'   => $parent->{'result'}->{'relation'},
                         'interest'   => $parent->{'result'}->{'interest'},
                         'comment'    => $parent->{'result'}->{'comment'},
                      });
    $parentdb->return;
    my $query2 = 'select last_insert_rowid() from parent';
    $parentdb->query($query2)->into(my ($parentid));

     $players_parents->create({
                                  'playerid' => $playerid,
                                  'parentid' => $parentid,
                             });

    if( $playerdb->error ) {
         error("DB error $playerdb->error");

         my $error = Dancer::Error->new(
                                        code    => 404,
                                        message => $playerdb->error
                                       );
        Dancer::Response->new->content($error->render);
    }
    else {
        my $shirtsizeid = $player->{'result'}->{'shirtsizeid'};
		$player->{'result'}->{'shirtsizeid'} = $shirtsizeid;
        $player->{'result'}->{'shirtsize_name'} = db->shirtsizetable
                                              ->read($player->{'result'}->{'shirtsizeid'})
                                              ->current->{'name'};
        my $suburbanid = $player->{'result'}->{'suburban'};
		$player->{'result'}->{'suburbanid'} = $suburbanid;
        $player->{'result'}->{'suburban'} = db->suburban
                                              ->read($player->{'result'}->{'suburban'})
                                              ->current->{'name'};
        $player->{'result'}->{'birthyear'} = $hetu->year();

        #-- email confirmation to player email
        sendmail({ to     => $player->{'result'}->{'email'},
                   player => $player->{'result'},
                   parent => $parent->{'result'} } );

        #-- email confirmation to parent email
        sendmail({ to     => $parent->{'result'}->{'email'},
                   player => $player->{'result'},
                   parent => $parent->{'result'} } );

        #-- email confirmation to club office
        sendmail({ to     => config->{'email'},
                   player => $player->{'result'},
                   parent => $parent->{'result'} } );

        #-- email to suburban contact persons
        my $suburban = db->suburban->read($suburbanid)->current;
        my $contacts = db->contact_suburban
                         ->read({ suburbanid => $suburbanid })->collection;

		foreach my $cs (@{$contacts}) {
			my $email = db->contact->read($cs->{'contactid'})->current->{'email'};
            sendmail({ to     => $email,
                       player => $player->{'result'},
                       parent => $parent->{'result'} } );
        }
        session->destroy;
        template 'registration_done', { player => $player, parent => $parent },
                                      { layout => undef };
    }
};


sub sendmail {
    my ($hArgs) = @_;
	my $subject = $hArgs->{'subject'};
	if ($subject eq '') {
		$subject = 'Futisklubi ilmoittautuminen',
	}

    debug("SENDMAIL to: ", $hArgs->{'to'});
	debug("SENDMAIL subject: ", $subject);
	
    if( $hArgs->{'to'} ne '' ) {
        email {
            from    => 'toimisto@tpv.fi',
            to      => $hArgs->{'to'},
            subject => $subject,
            body    => template('registration_done_email',
                                { player => $hArgs->{'player'},
                                  parent => $hArgs->{'parent'}, },
                                { layout => undef }),
            type    => 'html', # can be 'html' or 'plain'
            # Optional extra headers
            headers => {
                "X-Mailer"          => 'This fine Dancer application',
                "X-Accept-Language" => 'fi',
            }
        };
    }
}

#-- login, logout and other auth procedures
# NOTE: For some reasons this doesn't work on file header (Timo)
use AuthManager;

true;
