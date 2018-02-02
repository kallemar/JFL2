#=======================================================================
# package      JFLNetvisor
# state        public
# description  Member Registration system's Netvisor interface
#=======================================================================
package JFLNetvisor;
use Dancer ':syntax';
use Dancer::Plugin::ORMesque;
use Dancer::Plugin::REST;
use Dancer::Plugin::Auth::Basic;
use Data::Dumper;
use XML::Simple;	
use Requests;
use XML::Simple;

#-- set url prefix to .../netvisor/
prefix '/netvisor';


get '/getinvoicestatus' => sub {
        # TODO haetaan maksamattomat laskut ja tarkistetaan että onko ne maksettu

};


#=======================================================================
# route        	/netvisor/
# state        	private auth needed
# URL          	GET .../netvisor/
# TEST         	curl -u rest:Sala1234 -X GET \
#              	http://localhost:3000/netvisor/ID
# SAMPLE		curl -u rest:Sala1234 -X GET http://127.0.0.1:3000/netvisor/1
#-----------------------------------------------------------------------
# description  	Lähettää sanoman niistä pelaajista, jotka
#				- ovat oikealla kaudella (sesaonid)
#				- ei ole peruttu (cancelled)
#				- ei ole laskutettu
#				- on laskutettavissa (isinvoice=1) 
				
#=======================================================================
get '/:id' => sub {
	# luetaan pelaajat jotka pitää laskuttaa
    my $id = params->{'id'};
    my $players = db->player
                     ->read({ id => 3636,	#FIXME
	#						  seasonid  => $id,
   	#			              cancelled => undef,
  	#				          invoiced => undef,
  	#					          isinvoice => 0,	#FIXME 1
                            })->collection;
	my $season = db->season->read({ id => $id})->current;
	my $price_season = $season->{'price'};
	my $fraction_season = $season->{'fraction'};
    #debug Dumper($season);
	#debug Dumper($players);
    


	# get Netvisor auth details from config
    my $hAuth = {
        UserId => config->{'NetvisorRESTUserId'},
        Key => config->{'NetvisorRESTKey'},
        CompanyId => config->{'NetvisorShopVATID'},
        PartnerId => config->{'Netvisor_PartnerId'},
        PartnerKey => config->{'Netvisor_PartnerKey'},
		URL => config->{'Netvisor_RESTTestUrl'},
    };

	my $NetvisorClient = Requests->new($hAuth, config->{'Netvisor_RESTTestUrl'});


   
    foreach my $player (@{ $players }) {
		#luetaan pelaajan id
		my $playerid = $player->{'id'};
		
		# luetaan pelaajan kaupunginosa
		my $suburban = db->suburban->read({id => 8} )->current;
		my $price_suburban = $suburban->{'price'};
		my $fraction_suburban = $suburban->{'fraction'};
		
		
		#käytetään kaupunginosan hintaa jos on olemassa, muutoin käytetään kauden hintaan
		if ($price_suburban) {
			$player->{'price'} = $price_suburban;
			$player->{'fraction'} = $fraction_suburban;
		} else {
			$player->{'price'} = $price_season;
			$player->{'fraction'} = $fraction_season;
		}
		$player->{'price'} = $player->{'price'} / $player->{'fraction'};
		
		#set parent object
		my $parentid =
           db->player_parent->read({ playerid => $player->{'id'} })->current->{'parentid'};
		if( defined($parentid) ) {
			$player->{'parent'} = db->parent->read($parentid)->current;
		}
		#debug Dumper($player);

		# jos netvisorid on olemassa niin tehdään "Edit", jos sitä ei ole olemassa niin tehdään "Add"
		my $response;
		if (defined $player->{'netvisorid_customer'}) {
			debug "EDIT";
			$response = $NetvisorClient->PostCustomer($player, 'edit');
		} else {
			debug "ADD";
			$response = $NetvisorClient->PostCustomer($player, 'add', $player->{'netvisorid'});
		}
		
		debug @{ $response }[0];
		my $xml = new XML::Simple;
		my $data = $xml->XMLin(@{ $response }[0]);
		my $netvisorid;
	
		my $status;
		if(ref($data->{ResponseStatus}->{Status}) eq 'ARRAY') {
			$status = $data->{ResponseStatus}->{Status}->[0];
   			if ( $status eq 'FAILED') {
				debug "FAILED";
				debug "REASON: $data->{ResponseStatus}->{Status}->[1]";
				return "DONE"
			}
		}
		$status = $data->{ResponseStatus}->{Status};	#works only of one Status node in response
		if ( $status eq 'OK') {
			debug "SUCCESS";
			$netvisorid = "$data->{Replies}->{InsertedDataIdentifier}";
			debug "NEW ID: $netvisorid";
			
		} else {
			debug $status;
			return "DONE";
		}
		if (!defined $player->{'netvisorid_customer'}) {
			db->player->update({
		                    netvisorid_customer => $netvisorid,
		               },
		               {
		                    id => $playerid,
		               });
		 }

		#Product can be season or suburban. By default it is season but of suburban.price is defined then it is suburban
		my $Product;
		$Product->{'id'} = $season->{'id'};
		$Product->{'price'} = $player->{'price'};
		$Product->{'name'} = $season->{name};
		$Product->{'netvisorid'}	=  $season->{netvisorid};         
		#debug Dumper($Product);
		
		# jos netvisorid on olemassa niin tehdään "Edit", jos sitä ei ole olemassa niin tehdään "Add"
		if (defined $Product->{'netvisorid'}) {
			debug "EDIT";
			$response = $NetvisorClient->PostCustomer($Product, 'edit');
		} else {
			debug "ADD";
			$response = $NetvisorClient->PostProduct($Product, 'add', $Product->{'netvisorid'});
		}
		debug Dumper($response);	
        #my $xml = new XML::Simple;
		$data = $xml->XMLin(@{ $response }[0]);
		$status = $data->{ResponseStatus}->{Status};
		if ( $status eq 'FAILED') {
			debug "FAILED";
			debug "REASON: $data->{ResponseStatus}->{Status}->[1]";
			return "DONE"
			
		} elsif ( $status eq 'OK') {
			debug "SUCCESS";
			$netvisorid = "$data->{Replies}->{InsertedDataIdentifier}";
			debug "NEW ID: $netvisorid";
			
		} else {
			return "DONE";
		}
		if (!defined $season->{'netvisorid'}) {
			db->player->update({
		                    netvisorid => $netvisorid,
		               },
		               {
		                    id => $Product->{id},
		               });
		 }
		return "DONE";
		
		
        #send invoice
        my $order;
		PostSalesInvoice($order, undef, "Add", $id);        
        
         
		# talletetaan saatu netvisorid takaisin pelaajatietueelle
		db->player->update({
		                    netvisorid => $id,
		               },
		               {
		                    id => $playerid,
		               });
		 
		
	}	
};

1;
