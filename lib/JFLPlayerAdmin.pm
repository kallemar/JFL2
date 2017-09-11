package JFLPlayerAdmin;
use Dancer ':syntax';
use Dancer::Plugin::ValidateTiny;
use Dancer::Plugin::Database;
use Dancer::Plugin::ORMesque;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Email;
use Crypt::SaltedHash;
use PagerABC;
use Pager123;
use POSIX;
use Hetu;


prefix '/admin';

#=======================================================================
# route        /view/players
# state        private
# URL          GET localhost:3000/view/players
#-----------------------------------------------------------------------
# description  Default view. Lists all the players
#=======================================================================
get '/view/players' => require_any_role [qw(admin contact)] => sub {
    my $page    = defined(params->{page}) ? params->{page} :  1;
    my $current = defined(params->{char}) ? params->{char} : '';
    my $data    = {};
    my $user    = logged_in_user;
    my $search  = {
                      seasonid  => session('seasonid'),
                      lastname  => { -like => $current . '%'},
                      cancelled => undef,
                  };

    my @subids;
    if (user_has_role('contact')) {
        my $contactid = $user->{'contactid'};
        my $css = db->contact_suburban
                    ->select('suburbanid')
                    ->read({ contactid => $contactid})
                    ->collection;

        foreach my $cs (@{$css}) {
            push(@subids, $cs->{'suburbanid'});
        }
        $search->{'suburbanid'} = \@subids;

    }
    #debug($search);

    # --how many rows in the table
    my $count =  db->player->read($search)->count;

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $count,
                                'route'      => 'view/players' } );

    #-- read one page of rows from the table
    $data->{'players'}   = db->player
                             ->page($page, $P123->items_per_page)
                             ->read($search, ['suburbanid', 'teamid', 'birthyear', 'lastname', 'firstname'])
                             ->collection;

    #-- test-- some cpan module upgrade will break ORMesque page method
    #-- this is a workaround if this happens on production
    #use DBIx::Simple;
    #use SQL::Abstract::Limit;

    #my $dsn = config->{plugins}->{ORMesque}->{connection_name}->{dsn};
    #my $options = config->{plugins}->{ORMesque}->{connection_name}->{options};
    #my $db = DBIx::Simple->connect($dsn, '','', $options)
    #  or die DBIx::Simple->error;
    #$db->abstract = SQL::Abstract::Limit->new(limit_dialect => 'LimitOffset');
    #
    #$data->{'players'}  = $db->select("player",
    #                                  '*', $search,
    #                                  ['suburbanid', 'teamid', 'birthyear', 'lastname', 'firstname'],
    #                                  $P123->items_per_page, $P123->items_per_page * ($page-1) )
    #                         ->hashes;
    #-- end test

    #-- pass the pager object to the template. Object key must be P123
    $data->{'P123'} = $P123;

    #-- create new ABCPager object
    my $ABC = PagerABC->new( { 'current' => $current,
                               'table'   => 'player',
                               'column'  => 'lastname' } );

    #-- pass the pager object to the template. Object key must be ABC
    $data->{'ABC'} = $ABC;

    #-- suburbans needed on template
    my $subsearch = { seasonid => session('seasonid') };

    if(user_has_role('contact')) {
        $subsearch->{id} = \@subids;
    }
    #debug($subsearch);
    $data->{'suburbans'} = db->suburban
                             ->read($subsearch, ['name'])
                             ->collection;

    #-- teams needed on template
    my $teamsearch = { seasonid => session('seasonid') };

    if(user_has_role('contact')) {
        $teamsearch->{ suburbanid } = \@subids;
    }
    #debug($teamsearch);
    $data->{'teams'} = db->team
                         ->read($teamsearch, ['name'])
                         ->collection;

   #--get team and suburban
   foreach my $player (@{ $data->{'players'} }) {
       $player->{'team'}     =
           db->team->read( { id => $player->{'teamid'} } )->current->{name};
       $player->{'suburban'} =
           db->suburban->read( { id => $player->{'suburbanid'} } )->current->{name};

       my $parentid =
           db->player_parent->read({ playerid => $player->{'id'} })->current->{'parentid'};

       if( defined($parentid) ) {
            $player->{'parent'} = db->parent->read($parentid)->current;
       }
   }
   $data->{'user_roles'} = user_roles;
   template 'admin_view_players', $data;
};

#=======================================================================
# route        /view/cancelled
# state        private
# URL          GET localhost:3000/view/players
#-----------------------------------------------------------------------
# description  Lists all cancelled players
#=======================================================================
get '/view/cancelled' => require_any_role [qw(admin contact)] => sub {
    my $page    = defined(params->{page}) ? params->{page} :  1;
    my $current = defined(params->{char}) ? params->{char} : '';
    my $data    = {};
    my $user    = logged_in_user;
    my $search  = {
                      seasonid  => session('seasonid'),
                      lastname  => { -like => $current . '%'},
                      cancelled => { '!=', undef },
                  };

    my @subids;
    if (user_has_role('contact')) {
        my $contactid = $user->{'contactid'};
        my $css = db->contact_suburban
                    ->select('suburbanid')
                    ->read({ contactid => $contactid})
                    ->collection;

        foreach my $cs (@{$css}) {
            push(@subids, $cs->{'suburbanid'});
        }
        $search->{'suburbanid'} = \@subids;

    }
    #debug($search);

    # --how many rows in the table
    my $count =  db->player->read($search)->count;

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $count,
                                'route'      => 'view/cancelled' } );

    #-- read one page of rows from the table
    $data->{'players'}   = db->player
                             ->page($page, $P123->items_per_page)
                             ->read($search, ['suburbanid', 'teamid', 'birthyear', 'lastname', 'firstname'])
                             ->collection;

    #-- pass the pager object to the template. Object key must be P123
    $data->{'P123'} = $P123;

    #-- create new ABCPager object
    my $ABC = PagerABC->new( { 'current' => $current,
                               'table'   => 'player',
                               'column'  => 'lastname' } );

    #-- pass the pager object to the template. Object key must be ABC
    $data->{'ABC'} = $ABC;

    #-- suburbans needed on template
    my $subsearch = { seasonid => session('seasonid') };

    if(user_has_role('contact')) {
        $subsearch->{id} = \@subids;
    }
    #debug($subsearch);
    $data->{'suburbans'} = db->suburban
                             ->read($subsearch, ['name'])
                             ->collection;

    #-- teams needed on template
    my $teamsearch = { seasonid => session('seasonid') };

    if(user_has_role('contact')) {
        $teamsearch->{ suburbanid } = \@subids;
    }
    #debug($teamsearch);
    $data->{'teams'} = db->team
                         ->read($teamsearch, ['name'])
                         ->collection;

   #--get team and suburban
   foreach my $player (@{ $data->{'players'} }) {
       $player->{'team'}     =
           db->team->read( { id => $player->{'teamid'} } )->current->{name};
       $player->{'suburban'} =
           db->suburban->read( { id => $player->{'suburbanid'} } )->current->{name};

       my $parentid =
           db->player_parent->read({ playerid => $player->{'id'} })->current->{'parentid'};

       if( defined($parentid) ) {
            $player->{'parent'} = db->parent->read($parentid)->current;
       }
   }
   $data->{'user_roles'} = user_roles;
   template 'admin_view_players_cancelled', $data;
};
#=======================================================================
# route        /new/players
# state        private
# URL          GET localhost:3000/new/players
#-----------------------------------------------------------------------
# description  Show form to add new player.
#=======================================================================
get '/new/player' => require_any_role [qw(admin contact)] => sub {
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;
    my $teams = db->team
                   ->read({ seasonid => session('seasonid') })
                   ->collection;
	my $shirtsizetable = db->shirtsizetable->read->collection;
 debug("DEBUG");
   template 'admin_new_player', { suburbans => $suburbans,
				  shirtsizetable => $shirtsizetable,
                                  teams     => $teams };
};

#=======================================================================
# route        /new/player
# state        private
# URL          POST localhost:3000/new/player
#-----------------------------------------------------------------------
# description  Handeles posted new player data.
#=======================================================================
post '/new/player' => require_any_role [qw(admin contact)] => sub {
    my $params = params;
    my $data = validator($params, 'admin_player.pl');
    my $players = db->player;
    my $parent = db->parent;
    my $player_parent = db->player_parent;
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;
    my $teams = db->team
                   ->read({ seasonid => session('seasonid') })
                   ->collection;
	my $shirtsizetable = db->shirtsizetable->read->collection;


    if($data->{valid}) {
        my $hetu = Hetu->new({ hetu => $data->{'result'}->{'hetu'} });
			   debug("shirt:", $data->{'result'}->{'shirtsizeid'});
        $players->create({
                             firstname  => $data->{'result'}->{'firstname'},
                             lastname   => $data->{'result'}->{'lastname'},
                             hetu       => $data->{'result'}->{'hetu'},
                             street     => $data->{'result'}->{'street'},
                             zip        => $data->{'result'}->{'zip'},
                             city       => $data->{'result'}->{'city'},
                             phone      => $data->{'result'}->{'phone'},
                             email      => $data->{'result'}->{'email'},
                             suburbanid => $data->{'result'}->{'suburbanid'},
                             teamid     => $data->{'result'}->{'teamid'},
							 shirtsizeid => $data->{'result'}->{'shirtsizeid'},
							 wantstoplayingirlteam => $data->{'result'}->{'wantstoplayingirlteam'},
                             birthyear  => $hetu->year(),
                             sex        => $hetu->sex(),
                             seasonid   => session('seasonid'),
                             invoiced   => $data->{'result'}->{'invoiced'} eq '' ?
                                           undef :
                                           $data->{'result'}->{'invoiced'},
                             paid       => $data->{'result'}->{'paid'} eq '' ?
                                           undef :
                                           $data->{'result'}->{'paid'},
                             cancelled  => $data->{'result'}->{'cancelled'} eq '' ?
                                             undef :
                                            $data->{'result'}->{'cancelled'},                    
			 });
        my $query1 = 'select last_insert_rowid() from player';
        $players->query($query1)->into(my ($playerid));

        $parent ->create({
                         'firstname'  => $data->{'result'}->{'parent_firstname'},
                         'lastname'   => $data->{'result'}->{'parent_lastname'},
                         'phone'      => $data->{'result'}->{'parent_phone'},
                         'email'      => $data->{'result'}->{'parent_email'},
                         'relation'   => $data->{'result'}->{'parent_relation'},
                         'interest'   => $data->{'result'}->{'parent_interest'},
                         'comment'    => $data->{'result'}->{'parent_comment'},
                      });
        my $query2 = 'select last_insert_rowid() from parent';
        $parent->query($query2)->into(my ($parentid));

        $player_parent->create({
                                  'playerid' => $playerid,
                                  'parentid' => $parentid,
                             });

        template 'admin_new_player', { suburbans => $suburbans,
                                       teams     => $teams,
                                       valid     => 1 };
    }
    else {
       template 'admin_new_player', { suburbans => $suburbans,
                                      teams     => $teams,
									  shirtsizetable => $shirtsizetable,
                                      player    => $data->{'result'},
                                      valid     => 0 };
    }
};

#=======================================================================
#route         /edit/player/:id
# state        private
# URL          GET localhost:3000/edit/player
#-----------------------------------------------------------------------
# description  Opens prefilled edit player form.
#=======================================================================
get '/edit/player/:id' => require_any_role [qw(admin contact)] => sub {
    my $params = params;
    my $id = $params->{'id'};
    my $player = db->player->read($id)->current;
    my $parentid = db->player_parent
                     ->read({ playerid => $id })
                     ->current->{'parentid'};
    my $shirtsizetable = db->shirtsizetable->read->collection;

    #debug("shirtsizetable: ", $shirtsizetable); 
	
    my $parent;
    if(defined($parentid)) {
        my $p = db->parent->read($parentid)->current;
        $player->{'parent_firstname'} = $p->{'firstname'};
        $player->{'parent_lastname'}  = $p->{'lastname'};
        $player->{'parent_phone'}     = $p->{'phone'};
        $player->{'parent_email'}     = $p->{'email'};
        $player->{'parent_relation'}  = $p->{'relation'};
        $player->{'parent_interest'}  = $p->{'interest'};
        $player->{'parent_comment'}   = $p->{'comment'};

    }
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;
    my $teams = db->team
                   ->read({ seasonid => session('seasonid') })
                   ->collection;
    debug("shirtsizetable: ", $shirtsizetable);
    template 'admin_edit_player', {
                                       suburbans => $suburbans,
                                       teams     => $teams,
                                       player    => $player,
	 			   shirtsizetable => $shirtsizetable,
                                       user_roles => user_roles,
                                   };
};

#=======================================================================
# route        /edit/player
# state        private
# URL          POST localhost:3000/edit/player
#-----------------------------------------------------------------------
# description  Handles edit player form post.
#=======================================================================
post '/edit/player' => require_any_role [qw(admin contact)] => sub {
    my $params = params;
    my $id = $params->{'id'};
    my $data = validator($params, 'admin_player.pl');
	my $player = db->player->read({ id => $id })->current;
	
    #-- get player parent data
    my $parentid = db->player_parent
                     ->read({ playerid => $id })
                     ->current->{'parentid'};

    my $suburbans = db->suburban
                    ->read({ seasonid => session('seasonid') })
                    ->collection;
    my $teams = db->team->read->collection;
    my $shirtsizetable = db->shirtsizetable->read->collection;

    #debug("Data: ", $data);

    if($data->{valid}) {
       my $hetu = Hetu->new({ hetu => $data->{'result'}->{'hetu'} });
	   
	   #if ($player->{'sex') eq 2 ) {
	#		$data->{'result'}->{'wantstoplayingirlteam'} = 0;
	 #  }
	   
       db->player->update({
                               firstname  => $data->{'result'}->{'firstname'},
                               lastname   => $data->{'result'}->{'lastname'},
                               hetu       => $data->{'result'}->{'hetu'},
                               street     => $data->{'result'}->{'street'},
                               zip        => $data->{'result'}->{'zip'},
                               city       => $data->{'result'}->{'city'},
                               phone      => $data->{'result'}->{'phone'},
                               email      => $data->{'result'}->{'email'},
                               suburbanid => $data->{'result'}->{'suburbanid'},
                               teamid     => $data->{'result'}->{'teamid'},
							   shirtsizeid => $data->{'result'}->{'shirtsizeid'},
							  # wantstoplayingirlteam => $data->{'result'}->{'wantstoplayingirlteam'},
                               birthyear  => $hetu->year(),
                               sex        => $hetu->sex(),
                               invoiced   => $data->{'result'}->{'invoiced'} eq '' ?
                                             undef :
                                             $data->{'result'}->{'invoiced'},
                               paid       => $data->{'result'}->{'paid'} eq '' ?
                                              undef :
                                              $data->{'result'}->{'paid'},
                               isinvoice  => $data->{'result'}->{'isinvoice'},        
                           },
                           {
                               id => $id
                           });
		
	my $cancelmsgsent = 0;
	#my $cancelmsgsent = db->player->
    #                 ->read({ id => $id })
    #                 ->current->{'cancelmsgsent'};

		# Lähetetään toimistolle peruutusviesti jos peruutuskentässä havaitaan arvo
        if ($data->{'result'}->{'cancelled'} ne '') {
			# perumiskentästä löytyy päivämäärä				
			if ($cancelmsgsent eq 0) {
				# perumisviestiä ei ole vielä lähetetty
				db->player->update({
					cancelmsgsent => 1,
                    cancelled     => $data->{'result'}->{'cancelled'} eq '' ?
                                          undef :
                                          $data->{'result'}->{'cancelled'},
				},
				{
					id => $id
				});
				#-- email cancel info to club office
				sendmail( { to		=> 'toimisto@tpv.fi',
							#to     => config->{'email'},
							subject => 'Futisklubin osallistumisperuutus',
							templatename => 'cancellation_done_email.tt',
							player  => $data->{'result'},
							parent  => $data->{'result'} } );
			}
		} else {
			# perumiskentästä ei löydy päivämäärää
			db->player->update({
                cancelmsgsent  => 0,
            },
            {
                id => $id
            });
				 
		
		}

		db->parent->update({
                               'firstname'  => $data->{'result'}->{'parent_firstname'},
                               'lastname'   => $data->{'result'}->{'parent_lastname'},
                               'phone'      => $data->{'result'}->{'parent_phone'},
                               'email'      => $data->{'result'}->{'parent_email'},
                               'relation'   => $data->{'result'}->{'parent_relation'},
                               'interest'   => $data->{'result'}->{'parent_interest'},
                               'comment'    => $data->{'result'}->{'parent_comment'},
                           },
                           {
                               id => $parentid
                           });
        template 'admin_edit_player', { suburbans  => $suburbans,
                                        teams      => $teams,
										shirtsizetable => $shirtsizetable,
                                        player     => $data->{'result'},
                                        valid      => 1,
                                        user_roles => user_roles,
                                      };
    }
    else {
        template 'admin_edit_player', { suburbans  => $suburbans,
                                        teams      => $teams,
										shirtsizetable => $shirtsizetable,
                                        player     => $data->{'result'},
                                        valid      => 0,
                                        user_roles => user_roles,
                                      };
    }
};

#=======================================================================
#route         /delete/player/:id
# state        private
# URL          GET localhost:3000/delete/player
#-----------------------------------------------------------------------
# description  Deletes player for the system and redirects to the main
#              view.
#=======================================================================
get '/delete/player/:id' => require_role admin => sub {
    my $id = params->{'id'};
    my $parentid = db->player_parent
                     ->read({ playerid => $id })
                     ->current->{'parentid'};

    #--delete player parent relation
    if( defined($id) and defined($parentid) ){
        #debug($id, $parentid);

        db->player_parent->delete({ playerid => $id, parentid => $parentid });
    }
    #--delete parent
    if( defined($parentid) ) {
        db->parent->delete($parentid);
    }

    #--delete player
    db->player->delete($id);

    return redirect '/admin/view/players';
};

#=======================================================================
#route         /quick_search_players
# state        private
# URL          POST localhost:3000/quick_search_players
#-----------------------------------------------------------------------
# description  Search player by the search word.
#=======================================================================
any ['get', 'post'] => '/quick_search_players' => require_any_role [qw(admin contact)] => sub {
    my $search = defined(params->{'search'}) ? '%' . params->{'search'} . '%' : undef;
    my $page = defined(params->{page}) ? params->{page} : 1;
    my $user    = logged_in_user;
    my $qsearch  = {  seasonid => session('seasonid'),
                                 -or => {
                                            firstname => { -like => $search },
                                            lastname  => { -like => $search },
                                            hetu      => { -like => $search },
                                            phone     => { -like => $search },
                                            email     => { -like => $search },
                                            refno     => { -like => $search },
  	                                    }
                  };

    my @subids;
    if (user_has_role('contact')) {
        my $contactid = $user->{'contactid'};
        my $css = db->contact_suburban
                    ->select('suburbanid')
                    ->read({ contactid => $contactid})
                    ->collection;
        foreach my $cs (@{$css}) {
            push(@subids, $cs->{'suburbanid'});
        }
        $qsearch->{'suburbanid'} = \@subids;

   }
   #debug($qsearch);


    my $players = db->player;
    my $count   = $players->read($qsearch)->count;

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $count,
                                'route'      => 'quick_search_players',
                                'search'     => params->{'search'} } );

    my $result = $players->page($page, $P123->items_per_page)
                           ->read($qsearch, ['suburbanid', 'teamid', 'birthyear', 'lastname', 'firstname'])
                           ->collection ;

    #-- suburbans needed on template
    my $subsearch = { seasonid => session('seasonid') };

    if(user_has_role('contact')) {
        $subsearch->{id} = \@subids;
    }
    #debug($subsearch);
    my $suburbans = db->suburban
                      ->read($subsearch, ['name'])
                      ->collection;

    #-- teams needed on template
    my $teamsearch = { seasonid => session('seasonid') };

    if(user_has_role('contact')) {
        $teamsearch->{ suburbanid } = \@subids;
    }
    #debug($teamsearch);
    my $teams = db->team
                  ->read($teamsearch, ['name'])
                  ->collection;

    foreach my $player (@{ $result }) {
        $player->{'team'}     = db->team->read( { id => $player->{'teamid'} } )->current->{name};
        $player->{'suburban'} = db->suburban->read( { id => $player->{'suburbanid'} } )->current->{name};
    }

    template 'admin_view_players', {    players    => $result,
                                        P123       => $P123,
                                        suburbans  => $suburbans,
                                        teams      => $teams,
                                        user_roles => user_roles,
                                  };
};

#=======================================================================
#route         /admin/search_players
# state        private
# URL          POST localhost:3000/admin/search_players
#-----------------------------------------------------------------------
# description  Search player by the team or suburban.
#=======================================================================
any ['get', 'post']  => '/search_players' => require_any_role [qw(admin contact)] => sub {
    my $params  = params;
    my $search  = { seasonid => session('seasonid') };
    my $page    = defined(params->{page}) ? params->{page} : 1;
    my $user    = logged_in_user;
    my @subids;

    #--set search params to session
    session search_params => $params;

    #--check user rights
    if (user_has_role('contact')) {
        my $contactid = $user->{'contactid'};
        my $css = db->contact_suburban
                    ->select('suburbanid')
                    ->read({ contactid => $contactid})
                    ->collection;

        foreach my $cs (@{$css}) {
            push(@subids, $cs->{'suburbanid'});
        }
    }
    #debug('subids: ', @subids);

    #-- find out search parameters
    
    #--filter out cancelled players
    $search->{'cancelled'} = undef;
    
    if( params->{'suburban'} ne '') {
        $search->{'suburbanid'} =  params->{'suburban'};
    }
    elsif( user_has_role('contact') ){
        $search->{'suburbanid'} =  \@subids;
    }

    if(params->{'team'} ne '' ) {
        $search->{'teamid'} = params->{'team'};
    }

    if(params->{'invoiced'} ne '') {
        if( params->{'invoiced'} eq '1' ) {
            $search->{'invoiced'} =  { '!=', undef };
        }
        else {
            $search->{'invoiced'} = undef;
        }
    }

    if(params->{'paid'} ne '') {
        if( params->{'paid'} eq '1' ) {
            $search->{'paid'} =  { '!=', '' };
        }
        else {
            $search->{'paid'} = undef;
        }
    }

    my $players  = db->player;
    my $count    = $players->read({
                                    -and => $search
                                   })->count;

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $count,
                                'route'      => 'search_players',
                                'search'     => 'search_players' . '&' .
                                                'suburban=' . params->{'suburban'} . '&' .
                                                'team='     . params->{'team'}     . '&' .
                                                'invoiced=' . params->{'invoiced'} . '&' .
                                                'paid='     . params->{'paid'},
                                                
                              } );

    my $result = $players->page($page, $P123->items_per_page)
                           ->read({
                                    -and => $search
                                  }, ['suburbanid', 'teamid', 'birthyear', 'lastname', 'firstname'])->collection;

    #--suburbans needed on template
    my $subsearch = { seasonid => session('seasonid') };
    if(user_has_role('contact')) {
        $subsearch->{id} = \@subids;
    }
    #debug($subsearch);
    my $suburbans = db->suburban
                      ->read($subsearch, ['name'])
                      ->collection;

    #-- teams needed on template
    my $teamsearch = { seasonid => session('seasonid') };

    if(user_has_role('contact')) {
        $teamsearch->{ suburbanid } = \@subids;
    }
    #debug($teamsearch);
    my $teams = db->team
                  ->read($teamsearch, ['name'])
                  ->collection;

    foreach my $player (@{ $result }) {
        $player->{'team'}     = db->team->read( { id => $player->{'teamid'} } )->current->{name};
        $player->{'suburban'} = db->suburban->read( { id => $player->{'suburbanid'} } )->current->{name};
    }

    #debug($params);
    #debug("search: ", $search );

    template 'admin_view_players', {    players    => $result,
                                        P123       => $P123,
                                        suburbans  => $suburbans,
                                        teams      => $teams,
                                        search     => $params,
                                        user_roles => user_roles,
                                  };
};

#=======================================================================
#route         /admin/assign_players
# state        private
# URL          POST localhost:3000/admin/search_players
#-----------------------------------------------------------------------
# description  Assing players to the team
#=======================================================================
any['get', 'post'] => '/assign_players' => require_any_role [qw(admin contact)] => sub {
    my $page   = defined(params->{page}) ? params->{page} : 1;
    my $teamid = defined(params->{'team'}) ? params->{'team'} : params->{'search'};
    my $user   = logged_in_user;

    #debug(params->{'player'});
    #debug(params->{'team'});

    foreach my $id (params->{'player'}) {
        db->player->update({
                               teamid => params->{'team'},
                           },
                           {
                               id => $id
                           });
    }

    # read all the teams by teamid
    my $players = db->player->read({ teamid => $teamid });

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $players->count,
                                'route'      => 'assign_players',
                                'search'     => $teamid } );

    my $result = $players->page($page, $P123->items_per_page)
                           ->read({ teamid => $teamid },
                                  ['lastname', 'firstname'])
                           ->collection;


    foreach my $player (@{ $result }) {
        $player->{'team'}     = db->team->read( { id => $player->{'teamid'} } )->current->{name};
        $player->{'suburban'} = db->suburban->read( { id => $player->{'suburbanid'} } )->current->{name};
    }

    #-- find suburbans by role
    my @subids;
    if (user_has_role('contact')) {
        my $contactid = $user->{'contactid'};
        my $css = db->contact_suburban
                    ->select('suburbanid')
                    ->read({ contactid => $contactid})
                    ->collection;
        foreach my $cs (@{$css}) {
            push(@subids, $cs->{'suburbanid'});
        }
    }

    #--suburbans needed on template
    my $subsearch = { seasonid => session('seasonid') };
    if(user_has_role('contact')) {
        $subsearch->{id} = \@subids;
    }
    #debug($subsearch);
    my $suburbans = db->suburban
                      ->read($subsearch, ['name'])
                      ->collection;

    #-- teams needed on template
    my $teamsearch = { seasonid => session('seasonid') };

    if(user_has_role('contact')) {
        $teamsearch->{ suburbanid } = \@subids;
    }
    #debug($teamsearch);
    my $teams = db->team
                  ->read($teamsearch, ['name'])
                  ->collection;


    template 'admin_view_players', {
                                        P123       => $P123,
                                        players    => $result,
                                        suburbans  => $suburbans,
                                        teams      => $teams,
                                        user_roles => user_roles,
                                  };

};

#=======================================================================
#route         /admin/paid/player
# state        private
# URL          get localhost:3000/admin/paid/player
#-----------------------------------------------------------------------
# description  Assing players to the team
#=======================================================================
get '/paid/player/:id' => require_role admin => sub {
    my $id   = params->{'id'};
    my $page = defined(params->{page}) ? params->{page} : 1;
    my $char = defined(params->{char}) ? params->{char} : '';

    db->player->update({ paid => time },
                       { id   => $id });

    redirect '/admin/view/players?page=' . $page . '&char=' . $char;

};

#=======================================================================
#route         /cancel/player/:id
# state        private
# URL          GET localhost:3000/delete/player
#-----------------------------------------------------------------------
# description  Set current time to attribute cancel for the selected
#              player and redirects to the main view
#=======================================================================
get '/cancel/player/:id' => require_any_role [qw(admin contact)] => sub {
    my $id = params->{'id'};
    my $page = defined(params->{page}) ? params->{page} : 1;
    my $char = defined(params->{char}) ? params->{char} : '';

    #debug(params);

    db->player->update({
                           cancelled => time,
                       },
                       {
                           id => $id
                       });

    redirect '/admin/view/players?page=' . $page . '&char=' . $char;
};

sub sendmail {
    my ($hArgs) = @_;
	my $subject = $hArgs->{'subject'};
	if ($subject eq '') {
		$subject = 'Futisklubi ilmoittautuminen',
	}
	my $templatename = $hArgs->{'templatename'};
	if ($templatename eq '') {
		$templatename = 'registration_done_email',
	}

    debug("SENDMAIL to: ", $hArgs->{'to'});
	debug("SENDMAIL subject: ", $subject);
	debug("SENDMAIL template: ", $templatename);
	
    if( $hArgs->{'to'} ne '' ) {
        email {
            from    => 'toimisto@tpv.fi',
            to      => $hArgs->{'to'},
            subject => $subject,
            body    => template($templatename,
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

true;
