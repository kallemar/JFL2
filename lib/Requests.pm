package Requests;
use base RESTClient;

use strict;
use warnings;

use Dancer ':syntax';
use Data::Dumper;
use DateTime;
use Time::Piece;
use XML::XPath;
use XML::XPath::XMLParser;
use XML::Simple;
use XML::LibXML::SAX;

sub new {
    my $class = shift;
    my $hAuth = shift;
    my $Url = shift;

    my $self = $class->SUPER::new($Url, $hAuth);

    return $self;
}

#=============================================================================
# §function     PostCustomer
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  adds or edits customer depending the method (query string)
#-----------------------------------------------------------------------------
# §input        $player | player | object
# §input        $postMethod | post method, can be 'Add' or 'Edit' | string
# §return
#=============================================================================
sub PostCustomer {
    my $self = shift;
    my $player = shift;
    my $postMethod = shift;
    
    # Create XML for post   
    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $customer_xml = XML::XPath->new(context => $RootNode);
 
    _xmlset($customer_xml, "/customer/customerbaseinformation/internalidentifier", $player->{'id'});
    _xmlset($customer_xml, "/customer/customerbaseinformation/externalidentifier", ""); 		#$player->{'hetu'});
    _xmlset($customer_xml, "/customer/customerbaseinformation/organizationunitnumber", "");
    _xmlset($customer_xml, "/customer/customerbaseinformation/name", "$player->{'parent'}->{'firstname'} $player->{'parent'}->{'lastname'}");
    _xmlset($customer_xml, "/customer/customerbaseinformation/nameextension", '');
    _xmlset($customer_xml, "/customer/customerbaseinformation/streetaddress", $player->{'street'});
    _xmlset($customer_xml, "/customer/customerbaseinformation/additionaladdressline", '');
    _xmlset($customer_xml, "/customer/customerbaseinformation/city", $player->{'city'});
    _xmlset($customer_xml, "/customer/customerbaseinformation/postnumber", $player->{'zip'});
    _xmlset($customer_xml, "/customer/customerbaseinformation/country", "FI");
    _xmlSetAttribute($customer_xml, "/customer/customerbaseinformation/country", "type", "ISO-3166");
    _xmlset($customer_xml, "/customer/customerbaseinformation/customergroupname", "Futisklubi");
    _xmlset($customer_xml, "/customer/customerbaseinformation/phonenumber", $player->{'parent'}->{'phone'});
    _xmlset($customer_xml, "/customer/customerbaseinformation/faxnumber", '');
    _xmlset($customer_xml, "/customer/customerbaseinformation/email", $player->{'parent'}->{'email'});
    _xmlset($customer_xml, "/customer/customerbaseinformation/homepageuri", '');
    _xmlset($customer_xml, "/customer/customerbaseinformation/isactive", "1");
    _xmlset($customer_xml, "/customer/customerbaseinformation/isprivatecustomer", "1");
    _xmlset($customer_xml, "/customer/customerbaseinformation/emailinvoicingaddress", "");
    
    _xmlset($customer_xml, "/customer/customerfinvoicedetails/finvoiceaddress", '');
    _xmlset($customer_xml, "/customer/customerfinvoicedetails/finvoiceroutercode", '');


    _xmlset($customer_xml, "/customer/customerdeliverydetails/deliveryname", "");
    _xmlset($customer_xml, "/customer/customerdeliverydetails/deliverystreetaddress", "");
    _xmlset($customer_xml, "/customer/customerdeliverydetails/deliverycity", "");
    _xmlset($customer_xml, "/customer/customerdeliverydetails/deliverypostnumber", "");
    _xmlset($customer_xml, "/customer/customerdeliverydetails/deliverycountry", 'FI');
    _xmlSetAttribute($customer_xml, "/customer/customerdeliverydetails/deliverycountry", "type", "ISO-3166");
    

    _xmlset($customer_xml, "/customer/customercontactdetails/contactname", "");
    _xmlset($customer_xml, "/customer/customercontactdetails/contactperson", "");
    _xmlset($customer_xml, "/customer/customercontactdetails/contactpersonemail", "");
    _xmlset($customer_xml, "/customer/customercontactdetails/contactpersonphone", "");

    _xmlset($customer_xml, "/customer/customeradditionalinformation/comment", "Pelaaja: $player->{'firstname'} $player->{'lastname'}");
    _xmlset($customer_xml, "/customer/customeradditionalinformation/customeragreementidentifier", "");
    _xmlset($customer_xml, "/customer/customeradditionalinformation/customerreferencenumber", "");
    _xmlset($customer_xml, "/customer/customeradditionalinformation/directdebitbankaccount", "");
    _xmlset($customer_xml, "/customer/customeradditionalinformation/invoicinglanguage", "");
    _xmlSetAttribute($customer_xml, "/customer/customeradditionalinformation/invoicinglanguage", "type", "ISO-3166");
    _xmlset($customer_xml, "/customer/customeradditionalinformation/invoiceprintchannelformat", "");
    _xmlSetAttribute($customer_xml, "/customer/customeradditionalinformation/invoiceprintchannelformat", "type", "netvisor");
    _xmlset($customer_xml, "/customer/customeradditionalinformation/yourdefaultreference", "");
    _xmlset($customer_xml, "/customer/customeradditionalinformation/defaulttextbeforeinvoicelines", "");
    _xmlset($customer_xml, "/customer/customeradditionalinformation/defaulttextafterinvoicelines", "");
    _xmlset($customer_xml, "/customer/customeradditionalinformation/defaultsalesperson/salespersonid", "");
    _xmlSetAttribute($customer_xml, "/customer/customeradditionalinformation/defaultsalesperson/salespersonid", "type", "netvisor");

    my $data = $customer_xml->findnodes_as_string('/');
    my $response;
    if ($postMethod eq 'add') {
		$response = $self->SUPER::request("customer.nv", "POST", $data, "?method=$postMethod");
	} else {
		$response = $self->SUPER::request("customer.nv", "POST", $data, "?method=$postMethod&id=$player->{'netvisorid_customer'}");
	}
    return $response;
}

#=============================================================================
# §function     PostProduct
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  sends product to Netvisor
#-----------------------------------------------------------------------------
# §input        $Product | product | object
# §input        $postMethod | 'edit' or 'add' | string
# §input        $id | must be included if $postMethod = 'edit', defines the product to update | string
# §return
#=============================================================================
sub PostProduct {
    my $self = shift;
    my $Product = shift;
    my $postMethod = shift;
    my $id = shift;

    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $product_xml = XML::XPath->new(context => $RootNode);
    
    _xmlset($product_xml, "/product/productbaseinformation/productcode", $Product->{'id'} );
    _xmlset($product_xml, "/product/productbaseinformation/productgroup", 'Toimintamaksut');
    _xmlset($product_xml, "/product/productbaseinformation/name", $Product->{name});
    _xmlset($product_xml, "/product/productbaseinformation/description", '');
    _xmlset($product_xml, "/product/productbaseinformation/unitprice", $Product->{price} );
    _xmlSetAttribute($product_xml, "/product/productbaseinformation/unitprice", "type", "net");
	_xmlset($product_xml, "/product/productbaseinformation/unit", "kpl");
    _xmlset($product_xml, "/product/productbaseinformation/unitweight", '');
    _xmlset($product_xml, "/product/productbaseinformation/purchaseprice", "");
    _xmlset($product_xml, "/product/productbaseinformation/tariffheading", '');
    _xmlset($product_xml, "/product/productbaseinformation/comissionpercentage", "");
    _xmlset($product_xml, "/product/productbaseinformation/isactive", "1");
    _xmlset($product_xml, "/product/productbaseinformation/issalesproduct", "1");
    _xmlset($product_xml, "/product/productbaseinformation/inventoryenabled", "0");
    _xmlset($product_xml, "/product/productbookkeepingdetails/defaultvatpercentage", "0");
    my $data = $product_xml->findnodes_as_string('/');
    
	my $response;
	if ($postMethod eq 'add') {
		$response = $self->request("product.nv", "POST", $data, "?method=$postMethod");
	} else {
		$response = $self->SUPER::request("product.nv", "POST", $data, "?method=$postMethod&id=$Product->{'netvisorid'}");
	}

    return $response;
}

#=============================================================================
# §function     PostSalesInvoice
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  sends sales invoice or order to Netvisor
#-----------------------------------------------------------------------------
# §input        $Order | order | object
# §input        $InvoiceType | undef or 'Order'. If undef, type is SalesInvoice. | string
# $input        $postMethod | 'add' or 'edit' | string
# §input        $id | invoice's NetvisorKey. If $postMethod == 'edit', invoice's id is needed | string
# §return       
#=============================================================================
sub PostSalesInvoice {
    my $self = shift;
    my $player = shift;
    my $Product = shift;
    my $Discount = shift;
    my $id = shift; # NetvisorKey
	
     
    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $invoice_xml = XML::XPath->new(context => $RootNode);

	#INVOICE HEADER
    _xmlset($invoice_xml, "/salesinvoice/salesinvoicenumber", "");
    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoicedate", localtime->strftime("%Y-%m-%d"));			
    _xmlSetAttribute($invoice_xml, 	"/salesinvoice/salesinvoicedate", "format", "ansi");
    
    
    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoicereferencenumber", "");
    #_xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceamount", "1000" 	);
    #_xmlSetAttribute($invoice_xml, 	"/salesinvoice/salesinvoiceamount", "iso4217currencycode", "EUR");
    _xmlSetAttribute($invoice_xml, 	"/salesinvoice/salesinvoiceamount", "currencyrate", "0,00");
    _xmlset($invoice_xml, 			"/salesinvoice/selleridentifier", "");
    _xmlSetAttribute($invoice_xml, 	"/salesinvoice/selleridentifier", "type", "netvisor");
    _xmlset($invoice_xml, 			"/salesinvoice/sellername", "JFL");
    _xmlset($invoice_xml, 			"/salesinvoice/invoicetype", undef);
	_xmlset($invoice_xml, 			"/salesinvoice/salesinvoicestatus", "open");	# or "unsent"
    _xmlSetAttribute($invoice_xml, 	"/salesinvoice/salesinvoicestatus", "type", "netvisor");
    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoicefreetextbeforelines", "");
    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoicefreetextafterlines", "");
    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceourreference", "");
    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceyourreference", "");
    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceprivatecomment", "");
    
    
    _xmlset($invoice_xml, 			"/salesinvoice/invoicingcustomeridentifier", $player->{'netvisorid_customer'}) ;
    _xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicingcustomeridentifier", "type", "netvisor");
    _xmlset($invoice_xml, 			"/salesinvoice/invoicingcustomername", "$player->{'parent'}->{'firstname'} $player->{'parent'}->{'lastname'}");
    _xmlset($invoice_xml, 			"/salesinvoice/invoicingcustomernameextension", "");
    _xmlset($invoice_xml, 			"/salesinvoice/invoicingcustomeraddressline", $player->{'street'});
    _xmlset($invoice_xml, 			"/salesinvoice/invoicingcustomeradditionaladdressline", $player->{'street'});
    _xmlset($invoice_xml, 			"/salesinvoice/invoicingcustomerpostnumber", $player->{'zip'});
    _xmlset($invoice_xml, 			"/salesinvoice/invoicingcustomertown", $player->{'city'});
    _xmlset($invoice_xml, 			"/salesinvoice/invoicingcustomercountrycode", "FI");
    _xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicingcustomercountrycode", "type", "ISO 3316");
    
	_xmlset($invoice_xml, 			"/salesinvoice/deliveryaddressname", "$player->{'parent'}->{'firstname'} $player->{'parent'}->{'lastname'}");
	_xmlset($invoice_xml, 			"/salesinvoice/deliveryaddressline", $player->{'street'});
	_xmlset($invoice_xml,	 		"/salesinvoice/deliveryaddresspostnumber", $player->{'zip'});
	_xmlset($invoice_xml, 			"/salesinvoice/deliveryaddresstown", $player->{'city'});
	_xmlset($invoice_xml, 			"/salesinvoice/deliveryaddresscountrycode", "FI");
	_xmlSetAttribute($invoice_xml, 	"/salesinvoice/deliveryaddresscountrycode", "type", "ISO 3316");
	_xmlset($invoice_xml, 			"/salesinvoice/deliverymethod", "");
    _xmlset($invoice_xml, 			"/salesinvoice/deliveryterm", "");
    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoicetaxhandlingtype", "countrygroup");
    _xmlset($invoice_xml, 			"/salesinvoice/paymenttermnetdays", "14");
    _xmlset($invoice_xml, 			"/salesinvoice/paymenttermcashdiscountdays", "");
    _xmlset($invoice_xml, 			"/salesinvoice/paymenttermcashdiscount", "");
    _xmlSetAttribute($invoice_xml, 	"/salesinvoice/paymenttermcashdiscount", "type", "percentage");
    _xmlset($invoice_xml, 			"/salesinvoice/expectpartialpayments", "0");
    _xmlset($invoice_xml, 			"/salesinvoice/trydirectdebitlink", "");
    _xmlSetAttribute($invoice_xml, 	"/salesinvoice/trydirectdebitlink", "mode", "ignore_error");
    _xmlset($invoice_xml, 			"/salesinvoice/overridevouchersalesreceivablesaccountnumber", "");
    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceagreementidentifier", "");
    _xmlset($invoice_xml, 			"/salesinvoice/printchannelformat", "");
    _xmlSetAttribute($invoice_xml,  "/salesinvoice/printchannelformat", "type", "netvisor");
    _xmlset($invoice_xml, 			"/salesinvoice/secondname", "");
    _xmlSetAttribute($invoice_xml, 	"/salesinvoice/secondname", "type", "netvisor"); 
     
     #INVOICE LINE 1
	_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", $Product->{'netvisorid'});
	_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "netvisor");
	_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname", $Product->{'name'});
	_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", $Product->{'price'});
	_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");
	#xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitpurchaseprice", "");
	#xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitpurchaseprice", "type", "netvisor");
	_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "0");
	_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "vatcode", "KOMY");
	_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity", "1");
	#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinediscountpercentage", "");
	#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinefreetext", "");
	_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinevatsum", "");
	_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinesum", "");
	#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/accountingaccountsuggestion", "");
	#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/skipaccrual", "");
	#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionname", "Testi dimensio");
	#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionitem", "Testi dimension item");
	#_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionitem", "integrationdimensiondetailguid", "1");
    
    #_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoicecommentline", "");

     #SET INVOICE LINE 2
     if (defined $Discount) {
        
        _xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline");
        _xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline");
        _xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier");
        
       _xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "netvisor");
        $invoice_xml->setNodeText("//invoiceline[last()]/salesinvoiceproductline/productidentifier", config->{'Netvisor_TShirtDiscountProductID'});
        
        _xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname");
        $invoice_xml->setNodeText("//invoiceline[last()]/salesinvoiceproductline/productname", $Discount->{'name'});

        _xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice");
        _xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");
        $invoice_xml->setNodeText("//invoiceline[last()]/salesinvoiceproductline/productunitprice", $Discount->{'price'}); 

        _xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage");
        $invoice_xml->setNodeText("//invoiceline[last()]/salesinvoiceproductline/productvatpercentage", "0");
        _xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "vatcode", "KOMY");

		_xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity");
        $invoice_xml->setNodeText("//invoiceline[last()]/salesinvoiceproductline/salesinvoiceproductlinequantity", "1");


#		_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", config->{'Netvisor_TShirtDiscountProductID'});
#		_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "netvisor");
#		_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname", $Discount->{'name'});
#		_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", $Discount->{'price'});
#		_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");
#		_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "0");
#		_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "vatcode", "KOMY");
#		_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity", "1");
	}

	#INVOICE FOOTER
	if (defined $Discount) {
		#_xmlset($invoice_xml, 			"/salesinvoice/invoicevoucherlines/voucherline/linesum", $Product->{'price'}-$Discount->{'price'});
	} else {
		#_xmlset($invoice_xml, 			"/salesinvoice/invoicevoucherlines/voucherline/linesum", $Product->{'price'});
	}
	#_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicevoucherlines/voucherline/linesum", "type", "net");


    #_xmlset($invoice_xml, 			"/salesinvoice/invoicevoucherlines/voucherline/description", "");
    #_xmlset($invoice_xml, 			"/salesinvoice/invoicevoucherlines/voucherline/accountnumber", "3000");
    #_xmlset($invoice_xml, 			"/salesinvoice/invoicevoucherlines/voucherline/vatpercent", "0");
    #_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicevoucherlines/voucherline/vatpercent", "vatcode", "KOMY");
    #_xmlset($invoice_xml, 			"/salesinvoice/invoicevoucherlines/voucherline/skipaccrual", "1");
    #_xmlset($invoice_xml, 			"/salesinvoice/invoicevoucherlines/voucherline/dimension/dimensionname", "Testi dimensio");
    #_xmlset($invoice_xml, 			"/salesinvoice/invoicevoucherlines/voucherline/dimension/dimensionitem", "Testi dimension item");
#    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceaccrual/overridedefaultsalesaccrualaccountnumber", "0");
#    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceaccrual/salesinvoiceaccrualtype", "");
#    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceaccrual/accrualvoucherentry/month", "1");
#    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceaccrual/accrualvoucherentry/year", "2018");
#    _xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceaccrual/accrualvoucherentry/sum", "100");
   #_xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/mimetype", "Application/pdf");
   #_xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/attachmentdescription", "lasku");
   #_xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/filename", "lasku.pdf");
   #_xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/documentdata", "");
   #_xmlSetAttribute($invoice_xml, 	"/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/documentdata", "type", "pdf");
   
   #_xmlset($invoice_xml, 			"/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/printbydefault", "1");
   
# 	_xmlset($invoice_xml, 			"/salesinvoice/customtags/tag/tagname", "");
#    _xmlset($invoice_xml, 			"/salesinvoice/customtags/tag/tagvalue", "");#
#	_xmlSetAttribute($invoice_xml, 	"/salesinvoice/customtags/tag/tagvalue", "datatype", "date");
	
    my $data = $invoice_xml->findnodes_as_string('/');
    
    my $response = $self->SUPER::request("salesinvoice.nv", "POST", $data, "?method=add");
    #GetLog->debug("Response from API: $response->[1]");
    return $response;    
}

#=============================================================================
# §function     GetSalesInvoiceList
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  gets sales invoice or order list from API
#-----------------------------------------------------------------------------
# §input        $ListType | if undefined, gets sales invoice list, if 
#               "preinvoice", gets order list
# §return       $hSalesInvoices | hash with sales invoices' data | hash
#=============================================================================
sub GetSalesInvoiceList {
    my $self = shift;
    my $ListType = shift;

    my $querystr = "?ListType=$ListType";
    my $response = $self->SUPER::request("salesinvoicelist.nv", "GET", undef, $querystr);
    my $hSalesInvoices = $self->_xml2hash($response->[0]);

    return $hSalesInvoices;
}

#=============================================================================
# §function     GetSalesInvoice
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  gets sales invoice from API
#-----------------------------------------------------------------------------
# §input        $NetvisorKey | invoice id of the sales invoice | string
# §return       $hSalesInvoice | hash with sales invoice data | hash
#=============================================================================
sub GetSalesInvoice {
    my $self = shift;
    my $NetvisorKey = shift;

    my $querystr = "?netvisorkey=$NetvisorKey";
    my $response = $self->SUPER::request("getsalesinvoice.nv", "GET", undef, $querystr);
    my $hSalesInvoice = $self->_xml2hash($response->[0]);

    return $hSalesInvoice;
}

sub _xmlset {
    my ($Tree, $xpath, $value) = @_;

    if (!$Tree->exists($xpath)) {
        $Tree->createNode($xpath);
    }
    if((defined $value) and ($value ne '')) {
        $Tree->setNodeText($xpath, $value);
    }
}

sub _xmladd {
    use File::Basename;
  
    my ( $Tree, $xpath ) = @_;

    my $base = basename $xpath;
    $xpath = dirname $xpath;
   
    if ( ! $Tree->exists($xpath) ) {
        $Tree->createNode($xpath);
    }
    else {
        my $nodeSet = $Tree->find($xpath . "[last()]");
        my $parentNode = $nodeSet->get_node($nodeSet->size());
        my $newNode = XML::XPath::Node::Element->new($base, "");
        $parentNode->appendChild($newNode);

    }
}

sub _xmlSetAttribute {
    my $Tree = shift;
    my $xpath = shift;
    my $AttributeKey = shift;
    my $AttributeValue = shift;

    if(!$Tree->exists($xpath)) {
        $Tree->createNode($xpath);
    }
    my $nodeSet = $Tree->find($xpath);
    my $Node = $nodeSet->get_node($nodeSet->size());
    my $AttributeNode = XML::XPath::Node::Attribute->new($AttributeKey, $AttributeValue, '');
    $Node->appendAttribute($AttributeNode);
}


sub _xml2hash {
    my $self = shift;
    my $xmlString = shift;

    return XMLin($xmlString);
}

sub _xmlCreateNode {
	 my ($Tree, $xpath) = @_;

	$Tree->createNode($xpath);
 
}

1;

