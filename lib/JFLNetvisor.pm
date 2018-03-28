#=======================================================================
# package      JFLNetvisor
# state        public
# description  Member Registration system's Netvisor interface
#=======================================================================
package JFLNetvisor;
use Dancer ':syntax';
use Dancer::Plugin::Database;
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
	
	#get all unpaid invoices
	my $sth = database->prepare(
		'select * from player where netvisorid_invoice is not null and paid is null',
	);
	$sth->execute();
	
	my $runstatus->{'all unpaid invoices'} = 0;
	while( my $invoice= $sth->fetchrow_hashref) {
		++$runstatus->{'all unpaid invoices'};
		my $response = $NetvisorClient->GetSalesInvoice($invoice->{'netvisorid_invoice'});
		#TODO: error handling for $response get from Netvisor
		
		#status options: 'Unsent', 'Due for payment', 'Paid'
		if ($response->{'SalesInvoice'}->{'InvoiceStatus'} eq 'Paid') {
			database->quick_update('player', { id => $invoice->{'id'} }, { paid => 1 });
		}
	}
	return Dumper($runstatus);
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
#				- ovat oikealla kaudella (seasonid on annettu parametrina)
#				- ei ole peruttu (cancelled = undef)
#				- ei ole laskutettu (netvisorid_invoice = undef)
#				- on laskutettavissa (isinvoice=1) 
				
#=======================================================================
get '/:id' => sub {
	# luetaan pelaajat jotka pitää laskuttaa
    my $seasonid = params->{'id'};
    my @players = database->quick_select('player', 
													{
#														id => 1,
														seasonid  => $seasonid,
														cancelled => undef,
														netvisorid_invoice => undef,
														isinvoice => 1,
													});
	my $runstatus;
	$runstatus->{'all invoiceable players'} = @players;
	
	my $season = database->quick_select('season', { id => $seasonid} );
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

   
    foreach my $player (@players) {
		#luetaan pelaajan id
		my $playerid = $player->{'id'};
		
		# luetaan pelaajan kaupunginosa
		my $suburban = database->quick_select('suburban', { id => $player->{'suburbanid'} });
		
		#Product can be season or suburban. By default it is season but of suburban.price is defined then it is suburban
		if (defined $suburban->{'price'}) {
			$Product->{'name'} = "Toimintamaksu Futisklubi $suburban->{'name'} ($season->{'name'})";
			$Product->{'type'} = "suburban";
			$Product->{'price'} = $suburban->{'price'}/$suburban->{'fraction'};
			$Product->{'netvisorid_product'} =  $suburban->{'netvisorid_product'};         
		} else {
			$Product->{'name'} = "Toimintamaksu Futisklubi $season->{'name'}";
			$Product->{'type'} = "season";
			$Product->{'price'} = $season->{'price'}/$season->{'fraction'};
			$Product->{'netvisorid_product'} =  $season->{'netvisorid_product'};         
		}
		
		#set discounts. A discount is a separate product that has a negative price
		my $Discount;

		#A t-shirt case
		if (defined ($player->{'shirtsizeid'} )) {
			if ($player->{'shirtsizeid'} eq -1) {
				$Discount->{'id'} = "200";
				$Discount->{'name'} = "Pelipaitavähennys";
				$Discount->{'type'} = "discount";
				$Discount->{'price'} = "-10";
				$Discount->{'netvisorid'} =  config->{'Netvisor_TShirtDiscountProductID'};         
			}
		}
		#set $parent object for $player
		my $parentid = database->quick_select('player_parent',  { playerid => $playerid })->{'parentid'};
		if( defined($parentid) ) {
			$player->{'parent'} = database->quick_select('parent',  { id => $parentid });
		}
		

		### POST CUSTOMER
		#debug Dumper($player);
		my $response;
		my $mode  = defined( $player->{'netvisorid_customer'}) ? "edit" : "add";
		
		$response = $NetvisorClient->PostCustomer($player, $mode, $player->{'netvisorid_customer'});
		my $data = $xml->XMLin(@{ $response }[0]);
		
		if(ref($data->{ResponseStatus}->{Status}) eq 'ARRAY') {
			$status = $data->{ResponseStatus}->{Status}->[0];
   			if ( $status eq 'FAILED') {
				return "$status Cannot post a customer";
			}
		} else {
			$status = $data->{ResponseStatus}->{Status};
			if ( $status eq 'OK') {
				if ($mode eq "add") {
					$netvisorid = "$data->{Replies}->{InsertedDataIdentifier}";
				}
			} else {
				debug $status;
				return $status;
			}
		}
		
		#debug $playerid;
		#debug "netvisorid: $netvisorid";
		
		database->quick_update('player', { id => $playerid }, { netvisorid_customer => $netvisorid });	
		
		###POST INVOICE
        $response = $NetvisorClient->PostSalesInvoice($player, $Product, $Discount, $netvisorid);        
		$data = $xml->XMLin(@{ $response }[0]);
		my $netvisorid_invoice = $data->{'Replies'}->{'InsertedDataIdentifier'};
		#debug Dumper($response);
		
		#TODO Error handling
		
		# talletetaan saatu netvisorid takaisin pelaajatietueelle
		database->quick_update(
						'player',
					   {
		                    id => $playerid,
		               },
					   {
		                    netvisorid_invoice => $netvisorid_invoice,
		                    invoiced => time,
		               }
					);	
	}	
	return Dumper($runstatus);
};

1;
