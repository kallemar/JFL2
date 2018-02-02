package RESTClient;

use strict;
use warnings;

use Encode;
use REST::Client;
use DateTime;
use Time::HiRes qw(time);
use Data::Dumper;
use Digest::SHA qw(sha256_hex);
use XML::Simple;
use Tie::IxHash;
use Data::UUID;
#use Dancer ':syntax';

use constant CALL_TIMEOUT => 20;   #in seconds. Default is 300 (5 minutes)
use constant HTTP_CODE_OK => 200;
use constant REQUIREDKEYS => qw ( UserId Key CompanyId PartnerId PartnerKey ); # Remember to add stuff to ErrorDefinition in uc if you add data here

sub LogDebug {
    my $str = shift;
    my $struct = shift;
    #debug $str, $struct;
}

sub ErrorDefinition {
    return {
        'NO_USERID_SET' => "No Netvisor UserId set",
        'NO_KEY_SET' => "No Netvisor key set",
        'NO_COMPANYID_SET' => "No CompanyID(VAT ID) set",
        'NO_PARTNERID_SET' => "No Netvisor PartnerId set",
        'NO_PARTNERKEY_SET' => "No Netvisor PartnerKey set",
        'NO_TRANSACTION_ID' => "No TransactionID set",
        'CANT_PARSE_HASH' => "Error while parsing hash to xml",
        'CONNECTION_FAILED' => "connection failed with code #responsecode",
        'NO_METHOD_FOR_REQUEST' => "No method variable for request",
    };
}

#========================================================================================
# §function     new
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Object = FI_GAGAR::Netvisor::API::RESTClient->new();
# §example      $Client = FI_GAGAR::Netvisor::API::RESTClient->new(
#                             "integrationdemo.netvisor.fi",
#                             {
#                                 UserId => 'VD_83694_23334',
#                                 Key => '68A55E1969BF4FE331E714BB26A31CC8',
#                                 CompanyId => '1680636-7',
#                                 PartnerId => 'Vil_17520',
#                                 PartnerKey => 'F0D927BDF55AD8F4D15AB630601E08FC',
#                             }
#                         );
#----------------------------------------------------------------------------------------
# §description  Constructor for Netvisor RESTClient
#----------------------------------------------------------------------------------------
# §input        $URL | the url to connect to | string
# §input        $args | hash of required values | hash
#               Example:
#               UserId => 'VD_83694_23334',
#               Key => '68A55E1969BF4FE331E714BB26A31CC8',
#               CompanyId => '1680636-7',
#               PartnerId => 'Vil_17520',
#               PartnerKey => 'F0D927BDF55AD8F4D15AB630601E08FC',
# §return       $object | the object | object
#========================================================================================
sub new {
    my $class = shift;
    my $URL = shift;
    my $args = shift;

    # Check that all the required stuff is set in arguments.
    my @RequiredKeys = (REQUIREDKEYS);
    foreach my $RequiredKey (@RequiredKeys) {
        my $RequiredKeyUC = uc $RequiredKey;
        die("NO_" . $RequiredKeyUC . "_SET") unless exists $args->{$RequiredKey};
    };

    my $Client = _getClient();

    return bless {
        Url => $URL,
        Client => $Client,
        Args => $args,
    }, $class;
}


#========================================================================================
# §function     request
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Object = $RESTClient->request();
# §example      $Client = $RESTClient->request("customerlist.nv","GET");
#               $Client = $RESTClient->request("poststuff.nv","POST", {
#         crmprocess =>
#         {
#             content => "",
#             {
#                 processidentifier         => {content=>'54'},
#                 name                      => {content=>'Esimerkkitehtävä'},
#                 description               => {content=>'Tehtävän tuonti esimerkki'},
#                 processtemplatename       => {content=>'Esimerkki malli'},
#                 customeridentifier        => {content=>'33'},
#                 duedate                   => {content=>'2014-10-31',format => 'ansi},
#                 invoicingstatusidentifier => {content=>'1'},
#                 isclosed                  => {content=>'0'},
#             }
#         }
#               }
#----------------------------------------------------------------------------------------
# §description  Do a request against the url provided in new
#----------------------------------------------------------------------------------------
# §input        $path | the path of request | string
# §input        $method | the method used in the request | string
# §input        $data | optional data for the request | hash
# §return       $array | only response and the whole response | array
#========================================================================================
sub request {
    my $self = shift;
    my $path = shift;
    my $method = shift;
    # hash ( optional )
    my $data = shift;
    my $querystr = shift;

    my $xmlData = undef;
    if ( defined $data ) {
        eval {
            $xmlData = &_hash2xml($data);
        };
        if ( $@ ) {
            LogDebug('Eval:', $@);
        }
    }

    my $url = "https://". $self->{Url} . "/" . $path . "$querystr";
    # UserId -> X-Netvisor-Authentication-CustomerId and MAC calculations etc.
    my $Headers = &_getHeaders($self->{Args},$url);

    my $Client = $self->{Client};

    my $response = $Client->request($method,$url,$xmlData ,$Headers);
    #LogDebug("Response",$response);
    if ( $response->responseCode() != HTTP_CODE_OK ) {
       # LogDebug( 'CONNECTION_FAILED', { 'responsecode' => $response->responseCode()} );
    }

    return [$response->responseContent, $response];
}

#========================================================================================
# §function     convert_to_utf8
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       my $convertedstring = &convert_to_utf($hash);
#----------------------------------------------------------------------------------------
# §description  converts every entry from hash to utf-8
#----------------------------------------------------------------------------------------
# §return       $hash | Converted hash | hash
#========================================================================================
sub convert_to_utf8 {
    my $hash = shift;

    foreach my $key (keys %{$hash} ) {
        $hash->{$key} = encode_utf8($hash->{$key});
    }
   return $hash;
}


#========================================================================================
# §function     _getClient
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       $client = $self->_getClient();
#----------------------------------------------------------------------------------------
# §description  provides a REST client object
#----------------------------------------------------------------------------------------
# §return       $client | REST client object | object
#========================================================================================
sub _getClient {
    return REST::Client->new( { 'timeout' => CALL_TIMEOUT } );
}

#========================================================================================
# §function     _getHeaders
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       $client = $self->_getHeaders($args,$URL);
#----------------------------------------------------------------------------------------
# §description  Builds the header and calculates the SHA256 MAC to it
#----------------------------------------------------------------------------------------
# §input        $args | arguments | hash
# §input        $URL | URL to be called | string
# §return       $client | REST client object | object
#========================================================================================
sub _getHeaders {
    my $args = shift;
    my $url = shift;

    my $mapkeys =
    {
        'UserId' => 'X-Netvisor-Authentication-CustomerId',
        'PartnerId' => 'X-Netvisor-Authentication-PartnerId',
        'CompanyId' => 'X-Netvisor-Organisation-ID',
    };

    my $NetvisorHeader;

    foreach my $key (keys %$args) {
        $NetvisorHeader->{$mapkeys->{$key}} = $args->{$key} if $mapkeys->{$key};
    }

    # Use UUID from DATA::UUID as unique transaction identifier
    my $ug = Data::UUID->new;
    my $UUID = $ug->create();
    my $UUIDString = $ug->to_string($UUID);
    $NetvisorHeader->{'X-Netvisor-Authentication-TransactionId'} = $UUIDString;


    # Use HiRes time() function to get milliseconds
    # Time zone in timestamp has to be GMT+0 incording to Netvisor API documentation
    my $DateTime = DateTime->now(time_zone => 'Europe/London',epoch => time());
    my $FormattedDateTime = $DateTime->strftime("%F %T.%3N");
    $NetvisorHeader->{'X-Netvisor-Authentication-Timestamp'} = $FormattedDateTime;
    $NetvisorHeader->{'X-Netvisor-Authentication-Sender'} = "Vilkas";

    $NetvisorHeader->{'X-Netvisor-Interface-Language'} = "EN"; # We don't want to change the interface language from english.

    $NetvisorHeader->{'X-Netvisor-Authentication-MACHashCalculationAlgorithm'} = "SHA256";


    my @aMACkeys = (
        $url,
        $NetvisorHeader->{'X-Netvisor-Authentication-Sender'},
        $NetvisorHeader->{'X-Netvisor-Authentication-CustomerId'},
        $NetvisorHeader->{'X-Netvisor-Authentication-Timestamp'},
        $NetvisorHeader->{'X-Netvisor-Interface-Language'},
        $NetvisorHeader->{'X-Netvisor-Organisation-ID'},
        $NetvisorHeader->{'X-Netvisor-Authentication-TransactionId'},
        $args->{'Key'},
        $args->{'PartnerKey'},
    );

    my $MACString = join "&",@aMACkeys;
    my $MACSHA256 = sha256_hex($MACString);

    $NetvisorHeader->{'X-Netvisor-Authentication-MAC'} = $MACSHA256;

    #LogDebug("NetvisorHeader",$NetvisorHeader);

    return $NetvisorHeader;
}


#========================================================================================
# §function     _hash2xml
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       my $xmlData = _hash2xml($hash);
#----------------------------------------------------------------------------------------
# §description  converts hash to xml data with XMLout
#----------------------------------------------------------------------------------------
# §input        $hash | hash built for XMLout | hash
# §return       $xmlData | xml data as string | string
#========================================================================================
sub _hash2xml {
    my $data = shift;

    my $xmlData = XMLout (
        $data,
        KeyAttr => 'content',
        RootName => 'root',
    );
    #print $data;
    return $data;
}

1;
