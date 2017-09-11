package JFLExport;
use Dancer ':syntax';
use Dancer::Plugin::ValidateTiny;
use Dancer::Plugin::ORMesque;
use Dancer::Plugin::Auth::Extensible;
#use Text::CSV;
use Text::CSV::Encoded;
use DateTime;
use Hetu;

prefix '/admin';

get '/export/players' => require_role admin => sub {
    my $players = db->player->read({ seasonid => session('seasonid') })->collection;
	my $data;
	my $csv = Text::CSV::Encoded->new ({ sep_char => ';' });	

    my $header = 'id'            . ';';
    $header .= '#'               . ';';
    $header .= 'etunimi'         . ';';
    $header .= 'sukunimi'        . ';';
    $header .= 'hetu'            . ';';
    $header .= 'syntymävuosi'    . ';';
    $header .= 'sukupuoli'       . ';';
	$header .= 'haluaa pelata tyttöjoukkueessa' . ';';
	$header .= 'pelipaita'       . ';';
    $header .= 'osoite'          . ';';
    $header .= 'postinumero'     . ';';
    $header .= 'kaupunki'        . ';';
    $header .= 'puhelin'         . ';';
    $header .= 'sähköposti'      . ';';
    $header .= 'kaupunginosa'    . ';';
    $header .= 'joukkue'         . ';';
    $header .= 'laskutettu'      . ';';
    $header .= 'maksettu'        . ';';
    $header .= 'peruttu'         . ';';
    $header .= 'id'              . ';';
    $header .= 'etunimi'         . ';';
    $header .= 'sukunimi'        . ';';
    $header .= 'puhelin'         . ';';
    $header .= 'sähköposti'      . ';';
    $header .= 'suhde pelaajaan' . ';';
    $header .= 'kiinnostus'      . ';';
    $header .= 'muuta'           . ';';
    $header .= "\n";


    $data = $header;
    foreach my $player (@{ $players }) {
		debug($player);
        $player->{'team'}     =
            db->team->read( { id => $player->{'teamid'} } )->current->{name};
        $player->{'suburban'} =
            db->suburban->read( { id => $player->{'suburbanid'} } )->current->{name};
        $player->{'shirtsize_name'} =
            db->shirtsizetable->read( { id => $player->{'shirtsizeid'} } )->current->{name};

       my $parentid =
           db->player_parent->read({ playerid => $player->{'id'} })->current->{'parentid'};
       if( defined($parentid) ) {
            $player->{'parent'} = db->parent->read($parentid)->current;
       }

		my $invoiced  = '';
		if (defined $player->{invoiced} and $player->{invoiced}  ne '') {
			$invoiced  = DateTime->from_epoch(epoch => $player->{invoiced} )->dmy('.');
		}
		my $paid  = '';
		if (defined $player->{paid} and $player->{paid}  ne '') {
			$paid  = DateTime->from_epoch(epoch => $player->{paid} )->dmy('.');
		}
		my $cancelled  = '';
		if (defined $player->{cancelled} and $player->{cancelled}  ne '') {
			$cancelled  = DateTime->from_epoch(epoch => $player->{cancelled} )->dmy('.');			
		}
		
        my @columns;
        push(@columns, $player->{id});
        push(@columns, $player->{number});
        push(@columns, $player->{firstname});
        push(@columns, $player->{lastname});
        push(@columns, $player->{hetu});
        my $hetu = Hetu->new({ hetu => $player->{hetu} });
        push(@columns, $hetu->year());
        if ($hetu->sex() eq 1) {
            push(@columns, 'tyttö');
			if ($player->{wantstoplayingirlteam} eq 1) {
				push(@columns, 'Kyllä');
			} else {
				push(@columns, 'Ei');				
			}
        } else {
            push(@columns, 'poika');
			push(@columns, '');
        }
        push(@columns, $player->{shirtsize_name});		
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

        push(@columns, $player->{parent}->{id});
        push(@columns, $player->{parent}->{firstname});
        push(@columns, $player->{parent}->{lastname});
        push(@columns, $player->{parent}->{phone});
        push(@columns, $player->{parent}->{email});
        push(@columns, $player->{parent}->{relation});
        push(@columns, $player->{parent}->{interest});
        push(@columns, $player->{parent}->{comment});

        my $status = $csv->combine(@columns);
        $data .= $csv->string() . "\n";
    }
		return send_file( 	\$data, 
						#content_type => 'text/csv; charset=utf-8',
						content_type => 'text/csv',
                        filename     => 'pelaajat.csv' );
};

get '/export/coaches' => require_role admin => sub {
    my $coaches = db->coach->read({ seasonid => session('seasonid') })->collection;
    my $data;
	my $csv = Text::CSV::Encoded->new ({ sep_char => ';' });	

    my $header = 'id'          . ';';
    $header .= 'etunimi'       . ';';
    $header .= 'sukunimi'      . ';';
    $header .= 'osoite'        . ';';
    $header .= 'postinumero'   . ';';
    $header .= 'kaupunki'      . ';';
    $header .= 'puhelin'       . ';';
    $header .= 'sähköposti'    . ';';
    $header .= 'kaupunginosa'  . ';';
    $header .= 'joukkue'       . ';';

    $header .= "\n";

    $data = $header;
    foreach my $coach (@{ $coaches }) {
        $coach->{'team'}     =
            db->team->read( { id => $coach->{'teamid'} } )->current->{name};
        $coach->{'suburban'} =
            db->suburban->read( { id => $coach->{'suburbanid'} } )->current->{name};

        my @columns;
        push(@columns, $coach->{id});
        push(@columns, $coach->{firstname});
        push(@columns, $coach->{lastname});
        push(@columns, $coach->{street});
        push(@columns, $coach->{zip});
        push(@columns, $coach->{city});
        push(@columns, $coach->{phone});
        push(@columns, $coach->{email});
        push(@columns, $coach->{suburban});
        push(@columns, $coach->{team});

        my $status = $csv->combine(@columns);
        $data .= $csv->string() . "\n";
    }
   return send_file( \$data, content_type => 'text/csv',
                             filename     => 'ohjaajat.csv' );
};

get '/export/contacts' => require_role admin => sub {
    my $contacts = db->contact->read({ seasonid => session('seasonid') })->collection;
    my $c_s = db->contact_suburban;
    my $data;
	my $csv = Text::CSV::Encoded->new ({ sep_char => ';' });	

    my $header = 'id'          . ';';
    $header .= 'etunimi'       . ';';
    $header .= 'sukunimi'      . ';';
    $header .= 'osoite'        . ';';
    $header .= 'postinumero'   . ';';
    $header .= 'kaupunki'      . ';';
    $header .= 'puhelin'       . ';';
    $header .= 'sähköposti'    . ';';
    $header .= 'kaupunginosa(t)'  . ';';


    $header .= "\n";

    $data = $header;
    foreach my $contact (@{ $contacts }) {
		
	   my $subids = $c_s->read({ contactid => $contact->{id} })->collection;
       foreach my $sid (@{ $subids }) {
           $contact->{'suburban'} .= db->suburban->read( { id => $sid->{suburbanid} } )->current->{name};
           $contact->{'suburban'} .= ' ';
        }
        my @columns;
        push(@columns, $contact->{id});
        push(@columns, $contact->{firstname});
        push(@columns, $contact->{lastname});
        push(@columns, $contact->{street});
        push(@columns, $contact->{zip});
        push(@columns, $contact->{city});
        push(@columns, $contact->{phone});
        push(@columns, $contact->{email});
        push(@columns, $contact->{suburban});
        
        my $status = $csv->combine(@columns);
        $data .= $csv->string() . "\n";
    }
   return send_file( \$data, content_type => 'text/csv',
                             filename     => 'yhteyshenkilöt.csv' );
};
