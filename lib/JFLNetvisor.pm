#=======================================================================
# package      JFLNetvisor
# state        public
# description  Member Registration system's Netvisor interface
#=======================================================================
package JFLNetvisor;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::ORMesque;
use Dancer::Plugin::REST;
use Dancer::Plugin::Auth::Basic;
use Data::Dumper;
use XML::Simple;	
use Requests;

#-- set url prefix to .../netvisor/
prefix '/netvisor';


#=======================================================================
# route        	/getinvoicestatus
# state        	private auth needed
# URL          	GET .../netvisor/
# TEST         	curl -u rest:Sala1234 -X GET \
#              	http://localhost:3000/netvisor/getinvoicestatus
# SAMPLE		curl -u rest:Sala1234 -X GET http://127.0.0.1:3000/netvisor/getinvoicestatus
#-----------------------------------------------------------------------
# description  	Gets all unpaid player invoices and gets their status
#				if paid then player.paid field is updated to 1
#				Selection formula for unpaid invoices is:
#				select * from player where netvisorid_invoice is not null and paid is null;
				
#=======================================================================
get '/getinvoicestatus' => sub {
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
	
	#loop all invoices
	#FIXME: for some reason "netvisorid_invoice is not null and paid is null" query is not working
	my @invoices = database->quick_select('player', { 	paid => undef, 
														netvisorid_invoice => { 'ne', undef },
										});
	foreach my $invoice (@invoices) {
		my $response = $NetvisorClient->GetSalesInvoice($invoice->{'netvisorid_invoice'});
		#status options: 'Unsent', 'Due for payment', 'Paid'
		if ($response->{'SalesInvoice'}->{'InvoiceStatus'} eq 'Paid') {
			#update player.paid to 1
			database->quick_update('player', { id => $invoice->{'id'} }, { paid => 1 });
		}
	}
	return "DONE";
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
    my $seasonid = params->{'id'};
    my $players = db->player
                     ->read({ id => 3636,	#FIXME
	#						  seasonid  => $id,
   	#			              cancelled => undef,
  	#				          invoiced => undef,
  	#					          isinvoice => 0,	#FIXME 1
                            })->collection;
	my $season = db->season->read({ id => $seasonid})->current;
	my $xml = new XML::Simple;
	my $Product;
	my $netvisorid;
	my $status;
		

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
		my $suburban = db->suburban->read({id => $player->{'suburbanid'} } )->current;
		
		
		#Product can be season or suburban. By default it is season but of suburban.price is defined then it is suburban
		if (defined $suburban->{'price'}) {
			$Product->{'id'} = "B$suburban->{'id'}";
			$Product->{'name'} = "Futisklubitoiminta/kaupunginosa: $suburban->{'name'}";
			$Product->{'type'} = "suburban";
			$Product->{'price'} = $suburban->{'price'}/$suburban->{'fraction'};
			$Product->{'netvisorid'} =  $suburban->{'netvisorid'};         
		} else {
			$Product->{'id'} = "A$season->{'id'}";
			$Product->{'name'} = "Futisklubitoiminta: $season->{'name'}";
			$Product->{'type'} = "season";
			$Product->{'price'} = $season->{'price'}/$season->{'fraction'};
			$Product->{'netvisorid'} =  $season->{'netvisorid'};         
		}
		
		#set $parent object for $player
		my $parentid =
           db->player_parent->read({ playerid => $player->{'id'} })->current->{'parentid'};
		if( defined($parentid) ) {
			$player->{'parent'} = db->parent->read($parentid)->current;
		}
		

		# jos netvisorid on olemassa niin tehdään "Edit", jos sitä ei ole olemassa niin tehdään "Add"
		my $response;
		my $mode;
		if (defined $player->{'netvisorid_customer'}) {
			$mode = "edit";
		} else {
			$mode = "add";
		}
		$response = $NetvisorClient->PostCustomer($player, $mode, $player->{'netvisorid_customer'});
		
		
		#read the response
		my $data = $xml->XMLin(@{ $response }[0]);
		if(ref($data->{ResponseStatus}->{Status}) eq 'ARRAY') {
			$status = $data->{ResponseStatus}->{Status}->[0];
   			if ( $status eq 'FAILED') {
				debug Dumper($player);
				debug $mode;
				debug "FAILED: $data->{ResponseStatus}->{Status}->[1]";
				return "DONE"
			}
		} else {
			$status = $data->{ResponseStatus}->{Status};
			if ( $status eq 'OK') {
				#debug "SUCCESS PostCustomer";
				if ($mode eq "add") {
					$netvisorid = "$data->{Replies}->{InsertedDataIdentifier}";
					debug "ID: $netvisorid";
				}
			} else {
				debug $status;
				return "DONE";
			}
		}
		
		if (!defined $player->{'netvisorid_customer'}) {
			db->player->update({netvisorid_customer => $netvisorid }, {id => $playerid});
		}
		
		
		# jos netvisorid on olemassa niin tehdään "Edit", jos sitä ei ole olemassa niin tehdään "Add"
		if (defined $Product->{'netvisorid'}) {
			$mode = "edit";
		} else {
			$mode = "add";
		}
		$response = $NetvisorClient->PostProduct($Product, $mode, $Product->{'netvisorid'});
		
       
        #read the response
		$data = $xml->XMLin(@{ $response }[0]);
		if(ref($data->{ResponseStatus}->{Status}) eq 'ARRAY') {
			$status = $data->{ResponseStatus}->{Status}->[0];
   			if ( $status eq 'FAILED') {
				debug "FAILED";
				debug "REASON: $data->{ResponseStatus}->{Status}->[1]";
				return "DONE";
			}
		} else {
			$status = $data->{ResponseStatus}->{Status};
			if ( $status eq 'FAILED') {
				debug "FAILED";
				debug "REASON: $data->{ResponseStatus}->{Status}->[1]";
				return "DONE";		
			} elsif ( $status eq 'OK') {
				#debug "SUCCESS";
				if ($mode eq "add") {
					$netvisorid = "$data->{Replies}->{InsertedDataIdentifier}";
					debug "ID: $netvisorid";
				}		
			} else {
				return "DONE";
			}
		}

		if (!defined $Product->{'netvisorid'}) {
			if ($Product->{'type'} eq "season") {;
				db->season->update({netvisorid => $netvisorid }, {id => $seasonid});
			} else {
				db->suburban->update({netvisorid => $netvisorid }, {id => $player->{'suburbanid'}});
			}			
		}
		
		
		#make and send invoice
        my $id;
		$response = $NetvisorClient->PostSalesInvoice($player, $Product, $id);        
#        debug "ID: $id";
        
        #read the response
#        debug Dumper($response);
		$data = $xml->XMLin(@{ $response }[0]);
		debug Dumper($data);
		return "DONE";
		
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
