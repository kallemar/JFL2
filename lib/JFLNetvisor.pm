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
    my $id = params->{'id'};
    my $players = db->player
                     ->read({ seasonid  => $id,
   				              cancelled => undef,
  					          invoiced => undef,
  					          isinvoice => 0,	#FIXME 1
                            })->collection;
	
    debug Dumper($players);
    
    #TODO
    # loopataan läpi $players
	# 	tarkistetaan että onko $player->netvisorid tyhjä => kutsutaan postcustomer metodia "add" parameterilla, muutoin aina edit
	# 	lähetetään tuote jokaisen asiakkaan postauksen jälkeen
	#	lähetetään lasku jokaisen tuotteen lähetyksen jälkeen
	#	jokainen netvisor lähetys palauttaa netvisorid:n joka talletetaan tietokantaan
	#
	
};

get '/getinvoicestatus' => sub {
	# TODO haetaan maksamattomat laskut ja tarkistetaan että onko ne maksettu
};

1;
