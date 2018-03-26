package JFLAdmin;
use Dancer ':syntax';
use Dancer::Plugin::ValidateTiny;
use Dancer::Plugin::ORMesque;
use Dancer::Plugin::Database;
use Dancer::Plugin::Auth::Extensible;
use Crypt::SaltedHash;
use PagerABC;
use Pager123;
use POSIX;
use Hetu;
use Data::Dumper;

use JFLPlayerAdmin;

prefix '/admin';

get '/' => sub {
    redirect '/admin/view/players';
};

#=======================================================================
# route        /admin/set_season
# state        private
# URL          GET localhost:3000/admin/report
#-----------------------------------------------------------------------
# description  Show simple report page which answer frequently
#              asked questions
#=======================================================================
post '/set_season' => require_any_role [qw(admin contact)] => sub {
   my $params = params;
   session seasonid => $params->{'changeSeason'};
   debug "SESSION " . $params->{'changeSeason'} . " " . session("seasonid");
   return redirect '/admin/view/players';    
};

#=======================================================================
# route        /admin/report
# state        private
# URL          GET localhost:3000/admin/report
#-----------------------------------------------------------------------
# description  Show simple report page which answer frequently
#              asked questions
#=======================================================================player
get '/report' => require_role admin => sub {
    my $report;
    my $players = db->player;

    $report->{players_total} = $players->read({ seasonid => session('seasonid') })
                                       ->count;
    $report->{players_active} = $players->read({ seasonid  => session('seasonid'),
		                                         cancelled => undef,
		                                       })
                                       ->count;                                       
    $report->{players_girls} = $players->read({ seasonid  => session('seasonid'),
		                                        cancelled => undef,
                                                sex       => 1 })
                                       ->count;
    $report->{players_boys} = $players->read({ seasonid  => session('seasonid'),
		                                       cancelled => undef,
                                               sex       => 2 })
                                       ->count;

    $report->{players_cancelled} = $players->read({ seasonid  => session('seasonid'),
                                                    cancelled => { '!=', undef } })
                                       ->count;

    $report->{contacts} = db->contact
                           ->read({ seasonid => session('seasonid') })
                           ->count;

    $report->{coaches} = db->coach
                           ->read({ seasonid => session('seasonid') })
                           ->count;

    $report->{suburbans} = db->suburban
                             ->read({ seasonid => session('seasonid') })
                             ->count;

    $report->{teams} = db->team
                             ->read({ seasonid => session('seasonid') })
                             ->count;
    $report->{invoiced} = 0;
    $report->{paid} = 0;

    foreach my $player (@{ $players->read({seasonid => session('seasonid')})->collection }) {
        my $suburban = db->suburban->read($player->{suburbanid})->current;
        my $season = db->season->read({ id => $player->{seasonid} })->current;

        if( $player->{isinvoice} == 0 ) {
            $report->{noinvoice} += 1;
        }

        if( $player->{invoiced} && $player->{isinvoice} ) {
            $report->{invoiced} += 1;
        }

        if( $player->{paid} && $player->{isinvoice} ) {
            $report->{paid} += 1;
        }
    }
    $report->{outstanding} = $report->{invoiced} - $report->{paid};

    template 'admin_report', { report => $report };
};

#=======================================================================
# route        /report/data01
# state        private
# URL          GET localhost:3000//report/data01
#-----------------------------------------------------------------------
# description  Return report data as json structre.
#=======================================================================
get '/report/data01' => require_role admin => sub {
    my $subs = db->suburban
                 ->read({ seasonid => session('seasonid') })
                 ->collection;
    my @rows;
    foreach my $sub (@{$subs}) {
        my $player_count = db->player->read({ suburbanid => $sub->{id} })->count;

        push(@rows, { c => [ { v => $sub->{name} },  { v => $player_count } ] });
    }
    my @cols = (
                   { id =>'sub', label => 'Kaupuninosa',  type => 'string' },
                   { id =>'val', label => 'Value',  type => 'number' }

              );
    content_type 'application/json';
    return to_json { rows => \@rows, cols => \@cols };

};

#=======================================================================
# route        /report/data02
# state        private
# URL          GET localhost:3000//report/data02
#-----------------------------------------------------------------------
# description  Return report data as json structre.
#=======================================================================
get '/report/data02' => require_role admin => sub {
    my $players = db->player;
    my @ages = $players->query('SELECT distinct(birthyear) FROM player
                                WHERE seasonid=' . session('seasonid'))
                       ->arrays;

    my @rows;
    foreach my $age (@ages) {
        my $player_count = db->player
                             ->read({ seasonid  => session('seasonid'),
                                      birthyear => $age})
                             ->count;

        push(@rows, { c => [ { v => $age },  { v => $player_count } ] });
    }
    my @cols = (
                   { id =>'sub', label => 'Ikäluokka',  type => 'string' },
                   { id =>'val', label => 'Value',  type => 'number' }

              );
    content_type 'application/json';
    return to_json { rows => \@rows, cols => \@cols };

};


#=======================================================================
# route        /new/season
# state        private
# URL          GET localhost:3000/admin/new/season
#-----------------------------------------------------------------------
# description  Show form to add new season. Season must exist before
#              any other objects can be created.
#=======================================================================
get '/new/season' => require_role admin => sub {
    template 'admin_new_season', {};
};

#=======================================================================
# route        /new/season
# state        private
# URL          POST localhost:3000/admin/new/season
#-----------------------------------------------------------------------
# description  Handeles posted new player data.
#=======================================================================
post '/new/season' => require_role admin => sub {
    my $params = params;
    my $data   = validator($params, 'admin_season.pl');
    my $season = db->season;

    if($data->{valid}) {
        $season->create({
                             name        => $data->{'result'}->{'name'},
                             description => $data->{'result'}->{'description'},
                             startdate   => $data->{'result'}->{'startdate'},
                             enddate     => $data->{'result'}->{'enddate'},
                             isactive    => $data->{'result'}->{'isactive'},
                             netvisorid_product  => $data->{'result'}->{'netvisorid_product'},
                        });
        template 'admin_new_season', { season => { valid => 1 } };
    }
    else {
       template 'admin_new_season', { season => $data->{'result'} };
    }
};

#=======================================================================
# route        /view/seasons
# state        private
# URL          POST localhost:3000/admin/view/seasons
#-----------------------------------------------------------------------
# description  Shows all the seasons.
#=======================================================================
get '/view/seasons' => require_role admin => sub {
    my $page  = defined(params->{page}) ? params->{page} : 1;
    my $count = db->season->read()->count;

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $count,
                                'route'      => 'seasons',
                              } );

    my $seasons = db->season->page($page, $P123->items_per_page)
                   ->read->collection;
    debug ($seasons);
    template 'admin_view_seasons', { seasons => $seasons, P123 => $P123};
};

#=======================================================================
# route        /edit/seasons/id
# state        private
# URL          GET localhost:3000/admin/delete/123
#-----------------------------------------------------------------------
# description  Shows all the seasons.
#=======================================================================
get '/edit/season/:id' => require_role admin => sub {
   my $id = params->{'id'};
   my $season = db->season->read($id)->current;

   template 'admin_edit_season', { season => $season };
};

#=======================================================================
# route        /edit/seasons/id
# state        private
# URL          POST localhost:3000/admin/edit/season
#-----------------------------------------------------------------------
# description  Shows all the seasons.
#=======================================================================
post '/edit/season' => require_role admin => sub {
    my $params = params;
    my $data = validator($params, 'admin_season.pl');
    my $season = db->season;

    debug($data);

    if($data->{valid}) {
        #--only one season can be active. Mark othes deactive
        if( $params->{'isactive'} == 1 ) {
            $season->update({ isactive => 0 });
        }
        $season->update({
                             name        => $data->{'result'}->{'name'},
                             isactive    => $data->{'result'}->{'isactive'},
                             description => $data->{'result'}->{'description'},
                             startdate   => $data->{'result'}->{'startdate'},
                             enddate     => $data->{'result'}->{'enddate'},
                             netvisorid_product  => $data->{'result'}->{'netvisorid_product'},
                        },
                        {
                             id => $params->{'id'},
                        });

        template 'admin_edit_season', { season => $data->{'result'},
                                        valid  => 1, };
    }
    else {
       template 'admin_edit_season', { season => $data->{'result'},
                                       valid  => 0 };
    }
};

#=======================================================================
# route        /delete/season/id
# state        private
# URL          POST localhost:3000/admin/delete/season/123
#-----------------------------------------------------------------------
# description  Shows all the seasons.
#=======================================================================
get '/delete/season/:id' => require_role admin => sub {
   my $id = params->{'id'};
   my $suburban = db->season->delete($id);

   return redirect '/admin/view/seasons';
};

#=======================================================================
# route        /view/coaches
# state        private
# URL          GET localhost:3000/view/coaches
#-----------------------------------------------------------------------
# description  Lists all the coaches for the active season.
#=======================================================================
get '/view/coaches' => require_any_role [qw(admin contact)] => sub {
    my $page    = defined(params->{page}) ? params->{page} :  1;
    my $current = defined(params->{char}) ? params->{char} : '';
    my $data    = {};
    my $user    = logged_in_user;
    my $search  = {
                      seasonid  => session('seasonid'),
                      lastname  => { -like => $current . '%'}
                  };

    #-- get seasons
    $data->{seasons} = db->season->read()->collection;

    my @subids;
   # if (user_has_role('contact')) {
   #     my $contactid = $user->{'contactid'};
   #     my $css = db->contact_suburban
   #                 ->select('suburbanid')
   #                 ->read({ contactid => $contactid})
   #                 ->collection;
   #
   #     foreach my $cs (@{$css}) {
   #         push(@subids, $cs->{'suburbanid'});
   #     }
   #     $search->{'suburbanid'} = \@subids;
   #
   # }
    debug($search);

    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;
    my $teams = db->team
                  ->read({ seasonid => session('seasonid') })
                  ->collection;

    # --how many rows in the table
    my $count =  db->coach->read( $search,
                                 ['lastname', 'firstname'])->count;

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $count,
                                'route'      => 'view/coaches' } );

    #-- read one page of rows from the table
    $data->{'coaches'} = db->coach->page($page, $P123->items_per_page)
                             ->read( $search,
                                     ['lastname', 'firstname'])->collection;

    #-- pass the pager object to the template. Object key must be P123
    $data->{'P123'} = $P123;

    #-- create new ABCPager object
    my $ABC = PagerABC->new( { 'current' => $current,
                               'table'   => 'coach',
                               'column'  => 'lastname' } );

    #-- pass the pager object to the template. Object key must be ABC
   $data->{'ABC'} = $ABC;

    #--get team and suburban
    foreach my $coach (@{ $data->{'coaches'} }) {
        $coach->{'team'}     =
            db->team->read( { id => $coach->{'teamid'} } )->current->{name};
        $coach->{'suburban'} =
            db->suburban->read( { id => $coach->{'suburbanid'} } )->current->{name};
    }
    template 'admin_view_coaches', $data;
};

#=======================================================================
# route        /copy/coach
# state        private
# URL          POST localhost:3000/admin/new/coach
#-----------------------------------------------------------------------
# description  Copy coach to selected season.
#=======================================================================
post '/copy/coach' => require_any_role [qw(admin contact)] => sub {
   
    debug(params->{'coach'});
    debug(params->{'season'});
   
    if( not defined params->{'season'} or 
        not defined params->{'coach'} ) {
        return redirect '/admin/view/coaches';	   
    }
    
    #-- selected season id
    my $sid = params->{'season'};
    
    my $cids = params->{'coach'};
    
    if( ref($cids) ne 'ARRAY' ) {
	    $cids = [$cids];	
	}
   
    #-- loop trough selected contacts and copy to selected season
    foreach my $cid (@{$cids}) {
        my $coach = database->quick_select('coach', { id => $cid });
        my $user  = database->quick_select('users', { coachid => $cid });
                
        #-- set new seasonid
        $coach->{'seasonid'} = $sid;
        
        #-- delete some old data
        $coach->{'suburbanid'} = undef;
        $coach->{'teamid'} = undef;
        delete $coach->{'id'};
        delete $coach->{'created'};
        
        #-- insert coach to database
        database->quick_insert('coach', $coach);

        #-- find new coach id
        my $ncid = database->quick_select('coach', { email    => $coach->{'email'},
			                                         seasonid => $sid })
			               ->{'id'};
		
		#-- set new coachid to the user
		$user->{'coachid'} = $ncid;

        #-- delete old userid
        delete $user->{'id'};
        delete $user->{'created'};
        		
		#-- insert new user
		database->quick_insert('users', $user);
	
	    #-- find user id	
		my $uid = database->quick_select('users', { coachid => $ncid })
		                  ->{'id'};
		
		#-- set user role
		database->quick_insert('user_roles', { user_id => $uid,
			                                   role_id => 3 });		        
    }
    return redirect '/admin/view/coaches';
};

#=======================================================================
# route        /new/coach
# state        private
# URL          GET localhost:3000/admin/new/coach
#-----------------------------------------------------------------------
# description  Opens form to add new coach.
#=======================================================================
get '/new/coach' => require_any_role [qw(admin contact)] => sub {
   my $suburbans = db->suburban
                     ->read({ seasonid => session('seasonid') })
                     ->collection;
   my $teams = db->team
                 ->read({ seasonid => session('seasonid') })
                 ->collection;

   template 'admin_new_coach', { suburbans => $suburbans, teams => $teams };
};

#=======================================================================
# route        /new/coach
# state        private
# URL          POST localhost:3000/admin/new/coach
#-----------------------------------------------------------------------
# description  Handles new coach form post.
#=======================================================================
post '/new/coach' => require_any_role [qw(admin contact)] => sub {
    my $params = params;
    my $data = validator($params, 'admin_coach.pl');
    my $coaches = db->coach;
    my $users = db->users;
    my $user_id = undef;
    my $coachid = undef;
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;
    my $teams = db->team
                  ->read({ seasonid => session('seasonid') })
                  ->collection;


    if($data->{valid}) {
        #-- create password hash to be saved to database
        my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
        $csh->add($data->{'result'}->{'password'});
        my $salted = $csh->generate;

        $coaches->create({
                             firstname  => $data->{'result'}->{'firstname'},
                             lastname   => $data->{'result'}->{'lastname'},
                             street     => $data->{'result'}->{'street'},
                             zip        => $data->{'result'}->{'zip'},
                             city       => $data->{'result'}->{'city'},
                             phone      => $data->{'result'}->{'phone'},
                             email      => $data->{'result'}->{'email'},
                             suburbanid => $data->{'result'}->{'suburbanid'},
                             teamid     => $data->{'result'}->{'teamid'},
                             seasonid   => session('seasonid'),
                    });

        #-- find out coach's id
        my $query1 = 'select last_insert_rowid() from coach';
        $coaches->query($query1)->into(($coachid));

        #-- create user entry for contact
        $users->create({
                            username => $data->{'result'}->{'email'},
                            password => $salted,
                            coachid  => $coachid,
                       });

        #-- find out user's id
        my $query2 = 'select last_insert_rowid() from users';
        $users->query($query2)->into(($user_id));

        #-- add role into user_roles table
        db->user_roles->create({
                user_id => $user_id,
                role_id => 3, #-- this is coach role
        });
        template 'admin_new_coach', { suburbans => $suburbans,
                                      teams     => $teams,
                                      valid     => 1 };
    }
    else {
       template 'admin_new_coach', { suburbans => $suburbans,
                                     teams     => $teams,
                                     coach     => $data->{'result'},
                                     valid     => 0 };
    }
};

#=======================================================================
# route        /edit/coach/1
# state        private
# URL          GET localhost:3000/admin/edit/coach/1
#-----------------------------------------------------------------------
# description  Opens form to edit coach details.
#=======================================================================
get '/edit/coach/:id' => require_any_role [qw(admin contact)] => sub {
    my $id = params->{'id'};
    my $coach = db->coach->read($id)->current;
    my $user = db->users->read({ coachid => $coach->{'id'} })->current;

    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') },
                             [ 'name' ])
                      ->collection;
    my $teams = db->team
                  ->read({ seasonid => session('seasonid') },
                         [ 'name' ])
                  ->collection;

    template 'admin_edit_coach', { suburbans => $suburbans,
                                   teams => $teams,
                                   coach => $coach,
                                   user  => $user };
};

#=======================================================================
# route        /edit/coach
# state        private
# URL          POST localhost:3000/admin/edit/coach/1
#-----------------------------------------------------------------------
# description  Handels edit coach form POST.
#=======================================================================
post '/edit/coach' => require_any_role [qw(admin contact)] => sub {
    my $params = params;
    my $id = $params->{'id'};
    my $data = validator($params, 'admin_coach_edit.pl');
    my $user = db->users;
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') },
                             [ 'name' ])
                      ->collection;
    my $teams = db->team
                  ->read({ seasonid => session('seasonid') },
                         [ 'name' ])
                  ->collection;
    debug($data);

    my $password = undef;
    if($data->{valid}) {
	   $password = $user->read({ coachid => $id })->current->{'password'};

	   debug($id);

	   #--update password only if it is changed
	   if( $password ne $data->{'result'}->{'password'} ) {
	       #-- create password hash to be saved to database
           my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
           $csh->add($data->{'result'}->{'password'});
           $password = $csh->generate;

           $user->update({ password => $password }, { coachid => $id });
       }

       #--set email to username field
       $user->update({ username =>  $data->{'result'}->{'email'} },
                     { coachid  => $id });


       db->coach->update({
                               firstname     => $data->{'result'}->{'firstname'},
                               lastname      => $data->{'result'}->{'lastname'},
                               street        => $data->{'result'}->{'street'},
                               zip           => $data->{'result'}->{'zip'},
                               city          => $data->{'result'}->{'city'},
                               phone         => $data->{'result'}->{'phone'},
                               email         => $data->{'result'}->{'email'},
                               suburbanid    => $data->{'result'}->{'suburbanid'},
                               teamid        => $data->{'result'}->{'teamid'},
                           },
                           {
                               id => $id
                           });
        template 'admin_edit_coach', {
                                         suburbans => $suburbans,
                                         teams     => $teams,
                                         coach     => $data->{'result'},
                                         user      => $user->read({ coachid => $id })->current,
                                         valid     => 1,
                                     };
    }
    else {
        template 'admin_edit_coach', {
                                         suburbans => $suburbans,
                                         teams     => $teams,
                                         coach     => $data->{'result'},
                                         user      => $user->read({ coachid => $id })->current,
                                         valid     => 0
                                     };
    }
};

#=======================================================================
# route        /delete/coach/1
# state        private
# URL          GET localhost:3000/admin/delete/coach/1
#-----------------------------------------------------------------------
# description  Deletes coach from database.
#=======================================================================
get '/delete/coach/:id' => require_any_role [qw(admin contact)] => sub {
    my $id = params->{'id'};
    my $user_id = db->users
                    ->read({ coachid => $id })
                    ->current->{'id'};

    if( defined($user_id) and $user_id ne '' ) {
        #--delete user from users table
        db->users->delete($user_id);

        #--delete user from user_roles table
        db->user_roles->delete({ user_id => $user_id });
    }
    if( defined($id) and $id ne '') {

        #--finally delete contact
        db->coach->delete($id);
    }
    return redirect '/admin/view/coaches';
};

#=======================================================================
# route        /view/teams
# state        private
# URL          GET localhost:3000/admin/view/teams
#-----------------------------------------------------------------------
# description  List all teams.
#=======================================================================
get '/view/teams' => require_any_role [qw(admin contact)] => sub {
    my $page  = defined(params->{page}) ? params->{page} : 1;
    my $user    = logged_in_user;
    my $search  = {
                      seasonid  => session('seasonid'),
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
    debug($search);


    my $count = db->team->read($search)->count;

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $count,
                                'route'      => 'view/teams',
                              } );

   my $teams = db->team
                 ->page($page, $P123->items_per_page)
                 ->read($search, ['suburbanid', 'name'])
                 ->collection;

   foreach my $team (@{ $teams }) {
       $team->{'suburban'} = db->suburban
                               ->read( { id => $team->{'suburbanid'} } )
                               ->current->{name};
   }
    template 'admin_view_teams', { teams => $teams, P123 => $P123};
};

#=======================================================================
# route        /new/team
# state        private
# URL          GET localhost:3000/admin/new/suburban
#-----------------------------------------------------------------------
# description  Opens form to add new team.
#=======================================================================
get '/new/team' => require_any_role [qw(admin contact)] => sub {
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;

   template 'admin_new_team', { suburbans => $suburbans };
};

#=======================================================================
# route        /new/team
# state        private
# URL          POST localhost:3000/admin/new/team
#-----------------------------------------------------------------------
# description  Handeles posted new suburban data.
#=======================================================================
post '/new/team' => require_any_role [qw(admin contact)] => sub {
    my $params = params;
    my $data   = validator($params, 'admin_team.pl');
    my $teams  = db->team;
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;
    debug($data);

    if($data->{valid}) {
        debug("Data: ", $data);
        $teams->create({
                             name        => $data->{'result'}->{'name'},
                             description => $data->{'result'}->{'description'},
                             suburbanid  => $data->{'result'}->{'suburban'},
                             seasonid    => session('seasonid'),

                    });
        template 'admin_new_team', { suburbans => $suburbans,
                                     valid     => 1 };
    }
    else {
       template 'admin_new_team', { suburbans => $suburbans,
                                    team      => $data->{'result'},
                                    valid     => 0 };
    }
};

#=======================================================================
# route        /edit/team
# state        private
# URL          POST localhost:3000/admin/edit/edit
#-----------------------------------------------------------------------
# description  Opens prefilled form to edit team data
#=======================================================================
get '/edit/team/:id' => require_any_role [qw(admin contact)] => sub {
    my $id = params->{'id'};
    my $team = db->team->read($id)->current;
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;

   template 'admin_edit_team', { team      => $team,
                                 suburbans => $suburbans };
};

#=======================================================================
# route        /edit/team
# state        private
# URL          POST localhost:3000/admin/edit/team---------------
# description  Saves posted data to the database.
#=======================================================================
post '/edit/team' => require_any_role [qw(admin contact)] => sub {
    my $params = params;
    my $id = $params->{'id'};
    my $data = validator($params, 'admin_team.pl');
    my $teams = db->team;
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;

    if($data->{valid}) {
        $teams->update({
                            name        => $data->{'result'}->{'name'},
                            description => $data->{'result'}->{'description'},
                            suburbanid  => $data->{'result'}->{'suburban'},

                    },
                    {
                        id => $id
                    });

        template 'admin_edit_team', { suburbans => $suburbans,
                                      team      => db->team->read($id)->current,
                                      valid     => 1 };
    }
    else {
       template 'admin_edit_team', { suburbans => $suburbans,
                                     team      => $data->{'result'},
                                     valid     => 0 };
    }
};


#=======================================================================
# route        /delete/teams
# state        private
# URL          GET localhost:3000/admin/delete/team/1
#-----------------------------------------------------------------------
# description  Deletes team data from the database.
#=======================================================================
get '/delete/team/:id' => require_any_role [qw(admin contact)] => sub {
   my $id = params->{'id'};
   my $teams = db->team->delete($id);

   return redirect '/admin/view/teams';
};


#=======================================================================
# route        /view/suburbans
# state        private
# URL          GET localhost:3000/admin/vies/suburbans
#-----------------------------------------------------------------------
# description  List all suburbans.
#=======================================================================
get '/view/suburbans' => require_role admin => sub {
    my $page  = defined(params->{page}) ? params->{page} : 1;
    my $count = db->suburban
                 ->read({ seasonid => session('seasonid') })
                 ->count;

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $count,
                                'route'      => 'view/suburbans',
                              } );

    my $suburbans = db->suburban->page($page, $P123->items_per_page)
                      ->read({ seasonid => session('seasonid') },
                             ['name'])
                      ->collection;

    #--Contacts
    foreach my $sub (@{ $suburbans }) {
        my $contactids = db->contact_suburban
                        ->read( { suburbanid => $sub->{'id'} } )
                        ->collection;

        my @contacts;
        foreach my $csid (@{ $contactids })  {
            #debug($csid);
            push(@contacts, db->contact
                              ->read($csid->{'contactid'})
                              ->current);
        }
        $sub->{'contacts'} = \@contacts;
    }

    template 'admin_view_suburbans', {
                                         suburbans => $suburbans,
                                         P123 => $P123
                                     };
};

#=======================================================================
# route        /new/suburban
# state        private
# URL          GET localhost:3000/admin/new/suburban
#-----------------------------------------------------------------------
# description  Opens form to add new suburban.
#=======================================================================
get '/new/suburban' => require_role admin => sub {
    my $contacts = db->contact
                      ->read({ seasonid => session('seasonid') })
                      ->collection;
   template 'admin_new_suburban', { contacts => $contacts, };
};

#=======================================================================
# route        /new/suburban
# state        private
# URL          POST localhost:3000/admin/new/suburban
#-----------------------------------------------------------------------
# description  Handeles posted new suburban data.
#=======================================================================
post '/new/suburban' => require_role admin => sub {
    my $params = params;
    my $data = validator($params, 'admin_suburban.pl');
    my $contacts = db->contact
                      ->read({ seasonid => session('seasonid') },
                             ["lastname"])
                      ->collection;
    my $suburban = db->suburban;
    my $contacts_subs = db->contact_suburban;

    if($data->{valid}) {
        $suburban->create({
                                 name        => $data->{'result'}->{'name'},
                                 description => $data->{'result'}->{'description'},
                                 isvisible   => $data->{'result'}->{'isvisible'},
                                 seasonid    => session('seasonid'),
                                 netvisorid  => $data->{'result'}->{'netvisorid'},
                    });
        my $query = 'select last_insert_rowid() from suburban';
        $suburban->query($query)->into(my ($suburbanid));

        if(ref($data->{'result'}->{'contactid'}) eq 'ARRAY'){

            #--second add all the selected contacts to the suburban
           foreach my $contactid (@{ $data->{'result'}->{'contactid'} }) {
               $contacts_subs->create({
                                          contactid  => $contactid,
                                          suburbanid => $suburbanid,
                                      });
            }
        }
        else {
             $contacts_subs->create({
                                         contactid  => $data->{'result'}->{'contactid'},
                                         suburbanid => $suburbanid,
                                    });
        }


        template 'admin_new_suburban', { suburban => {},
                                         contacts => $contacts,
                                         valid => 1
                                       };
    }
    else {
        template 'admin_new_suburban', {
                                          suburban => $data->{'result'},
                                          contacts => $contacts,
                                          valid => 0
                                       };
    }
};

#=======================================================================
# route        /edit/suburban/id
# state        private
# URL          GET localhost:3000/admin/edit/suburban/1
#-----------------------------------------------------------------------
# description  Opens suburban edit page.
#=======================================================================
get '/edit/suburban/:id' => require_role admin => sub {
    my $id = params->{'id'};
    my $suburban = db->suburban->read($id)->current;
    my $contacts = db->contact
                      ->read({ seasonid => session('seasonid') },
                             ["lastname"])
                      ->collection;
    my $contacts_subs = db->contact_suburban->read->collection;
      	
    template 'admin_edit_suburban', { suburban => $suburban,
                                      contacts => $contacts,
                                      contact_suburban => $contacts_subs,
                                    };
};

#=======================================================================
# route        /edit/suburban
# state        private
# URL          POST localhost:3000/admin/edit/suburban
#-----------------------------------------------------------------------
# description  Updates suburban data to the database.
#=======================================================================
post '/edit/suburban' => require_role admin => sub {
    my $params = params;
    my $data = validator($params, 'admin_suburban.pl');
    my $suburban = db->suburban;
    my $contacts = db->contact
                     ->read({ seasonid => session('seasonid') },
                            ["lastname"])
                     ->collection;
    my $contacts_subs = db->contact_suburban;
    

    if($data->{valid}) {
        #--handle selected contacts
        #--first delete all contacts for the current suburban
        $contacts_subs->delete({ suburbanid => $params->{'id'} });

       if(ref($data->{'result'}->{'contactid'}) eq 'ARRAY'){

            #--second add all the selected contacts to the suburban
           foreach my $contactid (@{ $data->{'result'}->{'contactid'} }) {
               $contacts_subs->create({
                                          contactid  => $contactid,
                                          suburbanid => $params->{'id' },
                                      });
            }
        }
        else {
             $contacts_subs->create({
                                         contactid  => $data->{'result'}->{'contactid'},
                                         suburbanid => $params->{'id' },
                                    });
        }

        #--update suburban details
        $suburban->update({
                             name        => $data->{'result'}->{'name'},
                             description => $data->{'result'}->{'description'},
                             netvisorid  => $data->{'result'}->{'netvisorid'},
                             isvisible   => $data->{'result'}->{'isvisible'},
                          },
                          {
                              id => $params->{'id'}
                          });

        template 'admin_edit_suburban', { suburban => $data->{'result'},
                                          contacts => $contacts,
                                          contact_suburban => $contacts_subs->read->collection,
                                          valid => 1 };
    }
    else {
       template 'admin_edit_suburban', { suburban => $data->{'result'},
                                         contacts => $contacts,
                                         contact_suburban => $contacts_subs->read->collection,
                                         valid => 0 };
    }
};

#=======================================================================
# route        /delete/suburban
# state        private
# URL          POST localhost:3000/admin/delete/suburban/1
#-----------------------------------------------------------------------
# description  Deletes suburban data from the database.
#=======================================================================
get '/delete/suburban/:id' => require_role admin => sub {
   my $id = params->{'id'};

   db->contact_suburban->delete({ suburbanid => $id });
   db->suburban->delete($id);

   return redirect '/admin/view/suburbans';
};

#=======================================================================
# route        /view/contacts
# state        private
# URL          GET localhost:3000/admin/view/contacts
#-----------------------------------------------------------------------
# description  List all contact persons.
#=======================================================================
get '/view/contacts' => require_role admin => sub {
    my $page    = defined(params->{page}) ? params->{page} :  1;
    my $current = defined(params->{char}) ? params->{char} : '';
    my $data    = {};
    
    #-- read seasons
    $data->{'seasons'} = db->season->read()->collection;

    # --how many rows in the table
    my $count =  db->contact
                   ->read({ seasonid  => session('seasonid'),
                            lastname  =>
                                    { -like => $current . '%' } },
                                    ['lastname', 'firstname'] )
                   ->count;

    #-- create new pager object
    my $P123 = Pager123->new( { 'current'    => $page,
                                'totalcount' => $count,
                                'route'      => 'view/contacts' } );

    #-- read one page of rows from the table
    $data->{'contacts'} = db->contact->page($page, $P123->items_per_page)
                            ->read( {seasonid  => session('seasonid'),
                                     lastname  =>
                                       { -like => $current . '%'}},
                                    ['lastname', 'firstname'] )
                            ->collection;

    #-- pass the pager object to the template. Object key must be P123
    $data->{'P123'} = $P123;

    #-- create new ABCPager object
    my $ABC = PagerABC->new( { 'current' => $current,
                               'table'   => 'contact',
                               'column'  => 'lastname' } );

    #-- pass the pager object to the template. Object key must be ABC
    $data->{'ABC'} = $ABC;

   template 'admin_view_contacts', $data;
};

#=======================================================================
# route        /copy/contact
# state        private
# URL          POST localhost:3000/admin/new/contact
#-----------------------------------------------------------------------
# description  Open form to add new contact person.
#=======================================================================
post '/copy/contact' => require_role admin => sub {
   
    debug(params->{'contact'});
    debug(params->{'season'});
   
    if( not defined params->{'season'} or 
        not defined params->{'contact'} ) {
        return redirect '/admin/view/contacts';	   
    }
    
    #-- selected season id
    my $sid = params->{'season'};
    
    #-- selected contact ids
    my $cids = params->{'contact'};
    
    if( ref($cids) ne 'ARRAY' ) {
	    $cids = [$cids];	
	}
   
    #-- loop trough selected contacts and copy to selected season
    foreach my $cid (@{$cids}) {
        my $contact = database->quick_select('contact', { id => $cid });
        my $user = database->quick_select('users', { contactid => $cid });
        
        #-- set new seasonid
        $contact->{'seasonid'} = $sid;
        
        #-- delete old contactid
        delete $contact->{'id'};
        delete $contact->{'created'};        
        
        #-- insert new contact
        database->quick_insert('contact', $contact);
        
        #-- find new contacts id
        my $ncid = database->quick_select('contact', { email    => $contact->{'email'},
			                                           seasonid => $sid })
			               ->{'id'};
		
		#-- set new contactid to the user
		$user->{'contactid'} = $ncid;

        #-- delete old userid
        delete $user->{'id'};
        delete $user->{'created'};
                		
		#-- insert new user
		database->quick_insert('users', $user);
	
	    #-- find user id	
		my $uid = database->quick_select('users', { contactid =>  $ncid })
		                  ->{'id'};
		
		#-- set user role
		database->quick_insert('user_roles', { user_id => $uid,
			                                   role_id => 2 });		
    }
    return redirect '/admin/view/contacts';
};

#=======================================================================
# route        /new/contact
# state        private
# URL          GET localhost:3000/admin/new/contact
#-----------------------------------------------------------------------
# description  Open form to add new contact person.
#=======================================================================
get '/new/contact' => require_role admin => sub {
    my $suburbans = db->suburban
                      ->read({ seasonid => session('seasonid') })
                      ->collection;
   template 'admin_new_contact', { suburbans => $suburbans };                      
};

#=======================================================================
# route        /new/contact
# state        private
# URL          POST localhost:3000/admin/new/contact
#-----------------------------------------------------------------------
# description  Handle new contact person form post.
#=======================================================================
post '/new/contact' => require_role admin => sub {
    my $params = params;
    my $data = validator($params, 'admin_contact.pl');
    my $contacts = db->contact;
    my $contactid = undef;
    my $users = db->users;
    my $user_id = '';

    debug($data);

    if($data->{valid}) {
        #-- create password hash to be saved to database
        my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
        $csh->add($data->{'result'}->{'password'});
        my $salted = $csh->generate;

        $contacts->create({
                             firstname     => $data->{'result'}->{'firstname'},
                             lastname      => $data->{'result'}->{'lastname'},
                             street        => $data->{'result'}->{'street'},
                             zip           => $data->{'result'}->{'zip'},
                             city          => $data->{'result'}->{'city'},
                             phone         => $data->{'result'}->{'phone'},
                             email         => $data->{'result'}->{'email'},
                             seasonid      => session('seasonid'),
                          });
        #-- find out contact's id
        my $query1 = 'select last_insert_rowid() from contact';
        $contacts->query($query1)->into(($contactid));

        #-- create user entry for contact
        $users->create({
                            username      => $data->{'result'}->{'email'},
                            password      => $salted,
                            contactid     => $contactid,
                       });

        #-- find out user's id
        my $query2 = 'select last_insert_rowid() from users';
        $users->query($query2)->into(($user_id));

        #-- add role into user_roles table
        db->user_roles->create({
                user_id => $user_id,
                role_id => 2, #-- this is contact role
        });

        template 'admin_new_contact', { valid => 1 };
    }
    else {
       template 'admin_new_contact', {    contact => $data->{'result'},
                                          valid   => 0, };
    }
};

#=======================================================================
# route        /edit/contact/1
# state        private
# URL          GET localhost:3000/admin/edit/contact/1
#-----------------------------------------------------------------------
# description  Opens prefilled edit contact person form.
#=======================================================================
get '/edit/contact/:id' => require_role admin => sub {
    my $id = params->{'id'};
    my $contact = db->contact->read($id)->current;
    my $user = db->users->read({ contactid => $contact->{'id'} })->current;

    template 'admin_edit_contact', { contact => $contact,
		                              user => $user };
};

#=======================================================================
# route        /edit/contact
# state        private
# URL          POST localhost:3000/admin/edit/contact
#----------------------------------------------------------------------
# description  Handels edit person form post.
#=======================================================================
post '/edit/contact' => require_role admin => sub {
    my $params = params;
    my $id = $params->{'id'};
    my $data = validator($params, 'admin_contact.pl');
    my $user = db->users;

    debug($data);

    my $password = undef;
    if($data->{valid}) {
	   $password = $user->read({ contactid => $id })->current->{'password'};

	   #--update password only if it is changed
	   if( $password ne $data->{'result'}->{'password'} ) {
	       #-- create password hash to be saved to database
           my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
           $csh->add($data->{'result'}->{'password'});
           $password = $csh->generate;

           $user->update({ password => $password }, { contactid => $id });
       }

       #--set email to username field
       $user->update({ username =>  $data->{'result'}->{'email'} },
                     { contactid => $id });

       db->contact->update({
                               firstname     => $data->{'result'}->{'firstname'},
                               lastname      => $data->{'result'}->{'lastname'},
                               street        => $data->{'result'}->{'street'},
                               zip           => $data->{'result'}->{'zip'},
                               city          => $data->{'result'}->{'city'},
                               phone         => $data->{'result'}->{'phone'},
                               email         => $data->{'result'}->{'email'},
                           },
                           {
                               id => $id
                           });
       template 'admin_edit_contact', { contact => $data->{'result'},
                                       valid   => 1,
                                       user => $user->read({ contactid => $id })->current };
    }
    else {
       template 'admin_edit_contact', { contact => $data->{'result'},
                                       valid   => 0,
                                       user => $user->read({ contactid => $id })->current };
    }
};

#=======================================================================
# route        /delete/contact/1
# state        private
# URL          GET localhost:3000/admin/delete/contact/1
#----------------------------------------------------------------------
# description  Delete contact person from database.
#=======================================================================
get '/delete/contact/:id' => require_role admin => sub {
    my $id = params->{'id'};
    my $user_id = db->users
                    ->read({ contactid => $id })
                    ->current->{'id'};

    if( defined($user_id) and $user_id ne '' ) {
        #--delete user from users table
        db->users->delete($user_id);

        #--delete user from user_roles table
        db->user_roles->delete({ user_id => $user_id });
    }
    if( defined($id) and $id ne '') {
        #--delete contact from contact_suburban table
        db->contact_suburban->delete({ contactid => $id });

        #--finally delete contact
        db->contact->delete($id);
    }
    return redirect '/admin/view/contacts';
};

#=======================================================================
# route        /view/users
# state        private
# URL          GET localhost:3000/admin/view/users
#-----------------------------------------------------------------------
# description  List all contact persons.
#=======================================================================
get '/view/users' => require_role admin => sub {
   my $page    = defined(params->{page}) ? params->{page} :  1;
   my $current = defined(params->{char}) ? params->{char} : '';
   my $data    = {};

   # --how many rows in the table
   my $count =  db->users
                   ->read({ contactid => undef,
                            coachid   => undef })
                   ->count;

   #-- create new pager object
   my $P123 = Pager123->new( { 'current'    => $page,
                               'totalcount' => $count,
                               'route'      => 'view/users' } );

   #-- read one page of rows from the table
   my $users = db->users
                 ->page($page, $P123->items_per_page)
                 ->read({ contactid => undef,
                          coachid   => undef }, ['lastname', 'firstname'])
                 ->collection;

   $data->{'users'} = $users;

   #-- pass the pager object to the template. Object key must be P123
   $data->{'P123'} = $P123;

   #-- create new ABCPager object
   my $ABC = PagerABC->new( { 'current' => $current,
                              'table'   => 'users',
                              'column'  => 'lastname' } );

   #-- pass the pager object to the template. Object key must be ABC
   $data->{'ABC'} = $ABC;

   template 'admin_view_users', $data;
};

#=======================================================================
# route        /new/user
# state        private
# URL          GET localhost:3000/admin/new/user
#-----------------------------------------------------------------------
# description  Open form to add new contact person.
#=======================================================================
get '/new/user' => require_role admin => sub {
   my $user->{'roles_list'} = db->roles->read->collection;

   template 'admin_new_user', { user => $user };
};

#=======================================================================
# route        /new/user
# state        private
# URL          POST localhost:3000/admin/new/user
#-----------------------------------------------------------------------
# description  Handle new contact person form post.
#=======================================================================
post '/new/user' => require_role admin => sub {
    my $params = params;
    my $data = validator($params, 'admin_user.pl');
    my $users = db->users;
    my $user_id = '';

    debug($data);

    if($data->{valid}) {

        #-- create password hash to be saved to database
        my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
        $csh->add($data->{'result'}->{'password'});
        my $salted = $csh->generate;

        $users->create({
                            username      => $data->{'result'}->{'username'},
                            password      => $salted,
                            firstname     => $data->{'result'}->{'firstname'},
                            lastname      => $data->{'result'}->{'lastname'},
                            phone         => $data->{'result'}->{'phone'},
                    });
        #-- find out user's' id
        my $query = 'select last_insert_rowid() from users';
        $users->query($query)->into(($user_id));

        #-- add role into user_roles table
        db->user_roles->create({
                user_id => $user_id,
                role_id => 1, #-- this is admin role
        });

        template 'admin_new_user', { valid => 1 };
    }
    else {
       template 'admin_new_user', {
                                      user => $data->{'result'},
                                      valid => 0
                                  };
    }
};

#=======================================================================
# route        /edit/user/1
# state        private
# URL          GET localhost:3000/admin/edit/user/1
#-----------------------------------------------------------------------
# description  Opens prefilled edit user form.
#=======================================================================
get '/edit/user/:id' => require_role admin => sub {
    my $id = params->{'id'};
    my $user = db->users->read($id)->current;

    template 'admin_edit_user', { user => $user };
};

#=======================================================================
# route        /edit/user
# state        private
# URL          POST localhost:3000/admin/edit/user
#----------------------------------------------------------------------
# description  Handels edit user form post.
#=======================================================================
post '/edit/user' => require_role admin => sub {
    my $params = params;
    my $id = $params->{'id'};
    my $data = validator($params, 'admin_user.pl');

    debug($data);

    if($data->{valid}) {
        my $salted;
        if( $data->{'result'}->{'password'} eq
            db->users->read($id)->current->{password} ) {

            $salted = $data->{'result'}->{'password'}
        }
        else {
            my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
            $csh->add($data->{'result'}->{'password'});
            $salted = $csh->generate;
            $data->{'result'}->{'password'} = $salted;
        }
        db->users->update({
                              username  => $data->{'result'}->{'username'},
                              password  => $salted,
                              firstname => $data->{'result'}->{'firstname'},
                              lastname  => $data->{'result'}->{'lastname'},
                              phone     => $data->{'result'}->{'phone'},
                          },
                          {
                              id => $id
                          });

        template 'admin_edit_user', {
                                        user => $data->{'result'},
                                        valid => 1
                                    };
    }
    else {
        template 'admin_edit_user', {
                                        user => $data->{'result' },
                                        valid => 0
                                    };
    }
};

#=======================================================================
# route        /delete/user/1
# state        private
# URL          GET localhost:3000/admin/delete/user/1
#----------------------------------------------------------------------
# description  Delete contact person from database.
#=======================================================================
get '/delete/user/:id' => require_role admin => sub {
    my $id = params->{'id'};
    my $player = db->users->delete($id);

    return redirect '/admin/view/users';
};
true;
