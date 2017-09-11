#=======================================================================
# package      JFLProc
# state        public
# description  Member Registration system's ProCountor interface
#=======================================================================
package JFLProc;
use Dancer ':syntax';
use Dancer::Plugin::ORMesque;
use Dancer::Plugin::REST;
use Dancer::Plugin::Auth::Basic;

#-- set url prefix to .../proc/
prefix '/proc';


#=======================================================================
# route        /proc/
# state        private auth needed
# URL          GET .../proc/
# TEST         curl -u rest:Sala1234 -X GET \
#              http://localhost:3000/proc/
#-----------------------------------------------------------------------
# description  Returns all invoices in XML format where sent_to_proc
#              column is NULL. Set the current datetime to sent_to_proc
#              column.
#=======================================================================
get '/:id' => sub {
    my $id = params->{'id'};
    my $players = db->player
                     ->read({ seasonid  => $id, #session('seasonid'),
   				              cancelled => undef,
  					          invoiced => undef,
  					          isinvoice => 1,
                            })->collection;

    debug "Players: $players";

    #-- current year
    my $refno_base = (localtime)[5] + 1900;

    #-- today
    my $today = DateTime->now->ymd("");

    my @p_invoices;
    foreach my $player (@{ $players }) {
       my $parentid = db->player_parent
                      ->read({ playerid => $player->{id} })
                      ->current->{'parentid'};
                      
       my $parent = db->parent->read({ id => $parentid })->current;

	   foreach my $key (keys %{$player}) {
		    $player->{$key} = CleanUpStringRemove($player->{$key});
	   }
       debug "Player: ", $player;

       #--refno = currentyear . playerid . refno
       my $refno = $refno_base . $player->{id};
       $refno = _refno($refno);

       my $xml = {
				    'Version' => '1.2',
				    'content' => [''],
				    'SellerContactPersonName' => [''],
                    'InvoiceRecipientPartyDetails' => {
                        'InvoiceRecipientOrganisationName' => [ $player->{'firstname'} .' '. $player->{'lastname'} ],
                            'InvoiceRecipientPostalAddressDetails' => {
                            'InvoiceRecipientStreetName' => [$player->{'street'}],
                            'InvoiceRecipientTownName'   => [$player->{'city'}],
                            'InvoiceRecipientPostCodeIdentifier' => [$player->{'zip'}],
                            'CountryCode' => [''],
                        }
                    },
                    'BuyerPartyDetails' => {
                        'BuyerPartyIdentifier' => [''],
                        'BuyerOrganisationUnitNumber' => [''],
                        'BuyerOrganisationName' => [ $player->{'firstname'} .' '. $player->{'lastname'}],
                        'BuyerPostalAddressDetails' => {
                            'BuyerStreetName' => [$player->{'street'}],
                            'BuyerTownName' => [$player->{'city'}],
                            'BuyerPostCodeIdentifier' => [$player->{'zip'}],
                            'CountryCode' => [''],
                        }
                    },
                    'BuyerCommunicationDetails' => {
                        'BuyerEmailaddressIdentifier' => [ $parent->{'email'} ] },
                        'DeliveryPartyDetails' => {
                        'DeliveryOrganisationName' => [''],
                            'DeliveryPostalAddressDetails' => {
                                'DeliveryStreetName' => [''],
                                'DeliveryTownName' => [''],
                                'DeliveryPostCodeIdentifier' => [''],
                                'CountryCode' => [''],
                                'DeliveryPostofficeBoxIdentifier' => [''],
                            },
                        },
                    'DeliveryDetails' => {
                        'DeliveryPeriodDetails' => {
                            'StartDate' => {
                                'Format'  => 'CCYYMMDD',
                                'content' =>  ''
                            },
                            'EndDate'   => {
                                'Format'  => 'CCYYMMDD',
                                'content' =>  ''
                            }
                        }
                    },
                    'DeliveryMethodText' => [''],
                    'InvoiceDetails' => {
                        'InvoiceTypeCode' => ['INV01'],
                        'InvoiceDate' => {
                            'Format' => 'CCYYMDD',
                            'content' => [$today],
                        },
                        'OrderIdentifier' => [''],
                        'InvoiceFreeText' => [''],
                        'PaymentTermsDetails' => {
                            'InvoiceDueDate' => {
                                'Format' => 'CCYYMDD',
                                'content' => '',
                        },
                            'CashDiscountPercent' => [''],
                            'PaymentOverDueFineDetails' => {
                                'PaymentOverDueFinePercent' => [''],
                            }
                        }
                    },
                    'PaymentStatusDetails' => {
                        'PaymentMethodText' => ['']
                    },
                    'InvoiceRow' => getLineItems($player->{'id'}),

                    'SpecificationDetails' => {
                        'ProCountorInterfaceDetails' => {
                            'InterfacePassword' => [config->{ProCountorInterfacePassword}],
                            'InvoiceTypeCode' => ['M'],
                            'InvoiceStatusCode' => ['5'],
                            'InvoiceChannelCode' => ['1'],
                            'InvoiceLanguageCode' => ['FI'],
                            'InvoiceNotesText' => [''],
                            'UnitPricesIncludeTax' => [''],
                            'UpdatePartnerRegister' => [''],
                            'UpdateProductRegister' => [''],
                            'BuyerEInvoiceAddressIdentifier' => [''],
                            'BuyerAccountID' => [''],
                        }
                    },
                    'EpiDetails' => {
                        'EpiPartyDetails' => {
                            'EpiAccountID' => {
                                'IdentificationSchemeName' => 'BBAN/IBAN',
                                'content' => '',
                            }
                        },
                        'EpiPaymentInstructionDetails' => {
                            'EpiRemittanceInfoIdentifier' => {
                                'IdentificationSchemeName' => 'SPY',
                                'content' => $refno,
                            }
                        }
                    }
        };
        debug($xml);

        db->player->update({ invoiced => time,
                             refno    => $refno },
                           { id => $player->{'id'} });

        push(@p_invoices, $xml);
    }

    if($#p_invoices >= 0) {
		content_type 'application/xml';
        return to_xml { 'Finvoice' =>  \@p_invoices };
    }
    else {
		status_not_found("No invoices");
		return undef;
	}
};

#=======================================================================
# subroutine   getLineItems
# state        public
# input        $string | string containing offending character
# ouput        $string | string with valid xml characters
#-----------------------------------------------------------------------
# description  Converts all offending character to XML format
#=======================================================================
sub getLineItems {
    my ($id) = @_;
    my $player = db->player->read($id)->current;
    my $suburban = db->suburban->read($player->{suburbanid})->current;
    my $season = db->season->read({ id => $player->{seasonid} })->current;
    my $price = $season->{'price'} / $season->{'fraction'};
	
    if( defined($suburban->{'price'}) ) {
        if( $suburban->{'price'} ne '' ) {
            $price = $suburban->{'price'} / $suburban->{'fraction'};
        }
    }
	
	#annetaan 10 euron alennus jos pelipaidan koodi on -1 eli pelaaja
	#käyttää edelliskesän paitaa. T.Hopia 2.2.2017
	if ($player->{'shirtsizeid'} eq -1) {
		$price = $price - 10;
	}
	debug("Price: ", $price);
	
    my $xml = {
                  'ArticleIdentifier' => [''],
                  'ArticleName' => [config->{'ProCountorProduct'}],
                  'OrderedQuantity' => {
                      'QuantityUnitCode' => 'kpl',
                      'content' => 1,
                  },
                  'UnitPriceAmount' => {
                      'AmountCurrencyIdentifier' => 'EUR',
                      'content' => $price,
                  },
                  'RowNormalProposedAccountIdentifier' => [''],
                  'RowAccountDimensionText' => ['Tulolähde\Futisklubi'], #[config->{'ProCountorDimension'}],
                  'RowFreeText' => [''],
                  'RowDiscountPercent' => [''],
                  'RowVatRatePercent' => ['0'],
                  'RowIdentifier' => [''],
                  'RowQuotationIdentifier' => [''],
                  'RowAgreementIdentifier' => [''],
                  'RowDeliveryDetails' => {
                      'RowWaybillIdentifier' => ['']
                   },
              };

    return [$xml];
}

#=======================================================================
# subroutine   CleanUpStringRemove
# state        public
# input        $string | string containing offending character
# ouput        $string | string with valid xml characters
#-----------------------------------------------------------------------
# description  Converts all offending character to XML format
#=======================================================================
sub CleanUpStringRemove {
    my $string = shift;

    if( not defined($string)) {
        return $string;
    }

    # these should still be kept
    if($string =~ m/&.*;/) {
        debug 'Already encoded string not doing &amp;';
    } else {
        $string =~ s/&/&amp;/g;
    }
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/"/&quot;/g;
    $string =~ s/'/&apos;/g;

    $string = join("",
                   map { $_ > 255 ?              # if wide character...
                   '' :                          # NOTHING
                   chr($_) =~ /\n/ ?             # else if newline ...
                   chr($_) :                     # keep it
                   chr($_) =~ /[[:cntrl:]]/ ?    # else if control character ...
                   '' :                          # NOTHING
                   chr($_)                       # else as themselves
             } unpack("U*", $string));           # unpack Unicode characters

   return $string;
}

#=======================================================================
# subroutine   _refno
# state        public
# input        $number | umber for calculation | integer
# ouput        $refno | calculated reference number | integer
#-----------------------------------------------------------------------
# description  Perform Finnish reference number calculation.
#=======================================================================
sub _refno {
    my $number = shift;

    # temp variables
    my $calc = $number;
    my $refnum = undef;

    # base number must be all numbers and between 4 and 18 numbers long
    if ($number =~ /\D/ || length($number) > 19 || length($number) < 3) {
        error('Tried to calculate reference for a invalid number: ', $number);
        return undef;
    }

    # calculate reference number
    my @c = (7,3,1); #coefficients
    my $i=0;
    my $sum = 0;
    while ( $i < length($number) ) {
        $sum += ($calc % 10) * $c[$i % 3];
        debug("i: ", $i, " :Length of number: ", length($number), " :sum: ", $sum, " : multiplier: ", $c[$i % 3] );
        $calc = substr($number, 0, length($number) - ($i + 1) );
        debug("calc: ", $calc);
        $i++;
    }

    my $check = (10 - ($sum % 10)) % 10;

    $refnum = $number . $check;

    debug( 'Calculated reference number for number: ', $number, ' reference number: ', $refnum );

    return $refnum;
}

1;
