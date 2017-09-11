package AuthManager;
use Dancer ':syntax';
use Dancer::Plugin::Email;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::ValidateTiny;
use Dancer::Plugin::ORMesque;
use Digest::MD5 qw(md5 md5_hex md5_base64);

prefix undef;

### LOGIN & LOGOUT ###
get '/login/resetpassword' => sub {
    my $data;
	template 'login_resetpassword', $data, { layout => 'auth.tt' };
};

post '/login/resetpassword' => sub {
	my $params = params;
    my $data = validator($params, 'login_resetpassword.pl');
    my $timestamp = time;
    my $email = $data->{'result'}->{'email'};

    my $userid = db->users->read({username => $email})->current->{'id'};
    if ($userid) {
		$data->{valid} = 1;
	} else {
		$data->{valid} = 0;
	}
	debug $data;

	if($data->{valid}) {
		my $digest = md5_hex( ($timestamp + $userid), config->{reset_password_secret} );
		$data->{'user'}->{'id'} = $userid;
		$data->{'md5'}->{'timestamp'} = $timestamp;
		$data->{'md5'}->{'digest'} = $digest;

		# send mail
		sendmail_resetpassword({
								to => $email,
								data  => $data,
							  });
		template 'login_resetpassword_done', $data, { layout => 'auth.tt' };
	} else {
		template 'login_resetpassword', $data, { layout => 'auth.tt' };
	}
};

#from reset password email
get '/login/resetpasswordfor/id=*&digest=*&time=*' => sub {
    my ($id, $digest, $timestamp) = splat;

    #calculate a check value
    my $check = md5_hex( $timestamp + $id, config->{reset_password_secret} );

    #check time out
    if ((time-$timestamp) > config->{reset_password_timeout}) {
        error "FAILURE - timeout difference is ". (time-$timestamp);
    }
    else {
        # link is opened with an allowed time period
        if ($check eq $digest) {
            # search from database by using $id
            my $result = db->users->read( $id )->current;

            # start session
            session user => $result;

			# save params to session
			session session_id => $id;
			session session_digest => $digest;
			session session_timestamp => $timestamp;

            # open the form with prefilled values
            template 'login_password_reset', { result=> $result }, { layout => 'auth'};
        }
        else {
            error "FAILURE - digest doesn't match";
        };
    };
};

post '/login/password/reset' => sub {
    my $params = params;
    my $data = validator($params, 'login_password_reset.pl');

    if($data->{valid}) {
		# update the password
		debug 'password:' . $data->{'result'}->{'password'};

	    #-- create password hash to be saved to database
        my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
        $csh->add($data->{'result'}->{'password'});
        my $password = $csh->generate;

        db->users->update({ password => $password }, { id => session->{session_id} });

		template 'login_password_reset_done', undef, { layout => 'auth.tt' };
	} else {
		redirect '/login/password/reset';
	};

};

get '/login' => sub {
	my $data->{'path'} = params->{'return_url'};
    $data->{'flash'}->{'error'} = session->{login_error_message}; 
    session login_error_message => '';
	template 'login', $data, { layout => 'auth.tt' };
};

post '/login' => sub {
            my ($success, $realm) = authenticate_user(
                params->{username}, params->{password}
            );
            if ($success) {
                session logged_in_user => params->{username};
                session logged_in_user_realm => $realm;
                debug params->{path};
                return redirect params->{path};
            } else {
                # authentication failed
                session login_error_message =>  "Virhe: Väärä sähköpostiosoite tai salasana. Yritä uudelleen";
                return redirect '/login';
            }
};

get '/logout' => sub {
    session->destroy();

    if( params->{return_url}) {
        return redirect params->{return_url}
    }

    return redirect '/roster';
};

get '/login/denied' => sub {
    
    template 'access_denied', {}, { layout => undef };
};

sub sendmail_resetpassword {
    my ($hArgs) = @_;

	my $data = $hArgs->{'data'};

    if( $hArgs->{'to'} ne '' ) {
        email {
            from    => 'toimisto@tpv.fi',
            to      => $hArgs->{'to'},
            subject => 'Futisklubin salasanan palautus',
            body    => template('login_resetpassword_email',
							    { data => $data },
                                { layout => 'empty.tt' }),
            type    => 'html', # can be 'html' or 'plain'
            # Optional extra headers
            headers => {
                "X-Mailer"          => 'This fine Dancer application',
                "X-Accept-Language" => 'fi',
            }
        };
    }
};

true;

