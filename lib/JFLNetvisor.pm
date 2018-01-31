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
use Requests;

#-- set url prefix to .../netvisor/
prefix '/netvisor';


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
                     ->read({ id => 11331111,	#FIXME
							  seasonid  => $id,
   				              cancelled => undef,
  					          invoiced => undef,
  					          isinvoice => 0,	#FIXME 1
                            })->collection;
	my $season = db->season->read({ id => $id})->current;
	my $price_season = $season->{'price'};
	my $fraction_season = $season->{'fraction'};
    #debug Dumper($season);
    
    #avataan yhteys netvisoriin
    my $netvisorconn = Requests->new();
    debug Dumper($netvisorconn);
    
    foreach my $player (@{ $players }) {
		#luetaan pelaajan id
		my $playerid = $player->{'id'};
		
		# luetaan pelaajana kaupunginosa
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
		#debug Dumper($player);
		
		# jos netvisorid on olemassa niin tehdään "Edit", jos sitä ei ole olemassa niin tehdään "Add"
		if ($player->{'netvisorid' eq ''}) {
			debug "add";
			#PostCustomer('', "Add", $player);
		 }else {
			debug "edit";
			#PostCustomer('', "Edit", $player);
		 }
		 
		
                        
         #lähetetaan tuote netvisoriin
         my $product;
         PostSalesInvoice($product, undef, "Add", $id);
         debug Dumper($id);
        
         #lähetetään lasku
         my $order;
         PostSalesInvoice($order, undef, "Add", $id);
         debug Dumper($id);
         
          # talletetaan saatu netvisorid takaisin pelaajatietueelle
		 db->player->update({
                             netvisorid => $id,
                        },
                        {
                             id => $playerid,
                        });
		 
		
	}	
};

get '/getinvoicestatus' => sub {
	# TODO haetaan maksamattomat laskut ja tarkistetaan että onko ne maksettu
};

1;
