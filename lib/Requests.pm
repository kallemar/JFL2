package Requests;
use base RESTClient;

use strict;
use warnings;

use Dancer ':syntax';
use Data::Dumper;
use DateTime;
use XML::XPath;
use XML::Simple;
use XML::LibXML::SAX;
use Data::Dumper;

sub new {
    my $class = shift;

    my $Url = config->{Netvisor_RESTTestUrl};
    my $hAuth = $class->_getAuthData();
    my $self = $class->SUPER::new($Url, $hAuth);

    return $self;
}

#=============================================================================
# §function     GetCustomerList
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  gets customer list from API
#-----------------------------------------------------------------------------
# §input
# §return       $hResults | hash with customers' data | hash
#=============================================================================
sub GetCustomerList {
    my $self = shift;

    my $response = $self->SUPER::request("customerlist.nv", "GET");
    my $hCustomerList = $self->_xml2hash($response->[0]);

    return $hCustomerList;
}

#=============================================================================
# §function     GetCustomer
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  gets requested customer information
#-----------------------------------------------------------------------------
# §input        $customerId | customer's ID | string
# §return       $hResults | hash with customer's detailed information | hash
#=============================================================================
sub GetCustomer {
    my $self = shift;
    my $customerId = shift;

    my $response = $self->SUPER::request("getcustomer.nv", "GET", undef, "?id=$customerId");
    my $hCustomer = $self->_xml2hash($response->[0]);

    return $hCustomer;
}

#=============================================================================
# §function     PostCustomer
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  adds or edits customer depending the method (query string)
#-----------------------------------------------------------------------------
# §input        $Order | order | object
# §input        $postMethod | post method, can be 'Add' or 'Edit' | string
# §return
#=============================================================================
sub PostCustomer {
    my $self = shift;
    my $postMethod = shift;

    my $LanguageID = 'FI';
    my $Customer = shift;
	
	debug Dumper($Customer);
	
    # Create XML for post
    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $customer_xml = XML::XPath->new(context => $RootNode);
    _xmlset($customer_xml, "root/customer/customerbaseinformation/internalidentifier", $Customer->{'Alias'});
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/externalidentifier", $Customer->{'VATID'));
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/organizationunitnumber", "");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/name", $Customer->{'FullName'});
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/nameextension", $Customer->{'JobTitle'});
    _xmlset($customer_xml, "root/customer/customerbaseinformation/streetaddress", $Customer->{'Street'});
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/additionaladdressline", $Customer->{'Street2'});
    _xmlset($customer_xml, "root/customer/customerbaseinformation/city", $Customer->{'City'});
    _xmlset($customer_xml, "root/customer/customerbaseinformation/postnumber", $Customer->{'Zipcode'});

	_xmlset($customer_xml, 			"root/customer/customerbaseinformation/country", 'FI');
	_xmlSetAttribute($customer_xml, "root/customer/customerbaseinformation/country", "type", "ISO-3166");

#    _xmlset($customer_xml, "root/customer/customerbaseinformation/customergroupname", config->{'netvisor_customergroupname'} );
    _xmlset($customer_xml, "root/customer/customerbaseinformation/phonenumber", $Customer->{'Phone'});
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/faxnumber", $Customer->{'Fax'});
    _xmlset($customer_xml, "root/customer/customerbaseinformation/email", $Customer->{'EMail'});
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/homepageuri", $Customer->{'URL'));
    _xmlset($customer_xml, "root/customer/customerbaseinformation/isactive", "1");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/isprivatecustomer", "1");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/emailinvoicingaddress", $Customer->{'EMail'});

#    _xmlset($customer_xml, "root/customer/customerfinvoicedetails/finvoiceaddress", $Customer->{'NetvisorEInvoiceAddress'));
#    _xmlset($customer_xml, "root/customer/customerfinvoicedetails/finvoiceroutercode", $Customer->{'NetvisorEInvoiceOperatorAddress'));

#    if(defined $ShippingAddress) {
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliveryname", $ShippingAddress->{'FullName'));
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverystreetaddress", $ShippingAddress->{'Street'));
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverycity", $ShippingAddress->{'City'));
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverypostnumber", $ShippingAddress->{'Zipcode'));
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverycountry", $ShippingAddress->{'Country')->{'Code2'});
#        _xmlSetAttribute($customer_xml, "root/customer/customerdeliverydetails/deliverycountry", "type", "ISO-3166");
#    } else {
        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliveryname", $Customer->{'FullName'});
        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverystreetaddress", $Customer->{'Street'});
        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverycity", $Customer->{'City'});
        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverypostnumber", $Customer->{'Zipcode'});
	_xmlset($customer_xml, 			"root/customer/customerdeliverydetails/deliverycountry", 'FI');
	_xmlSetAttribute($customer_xml, "root/customer/customerdeliverydetails/deliverycountry", "type", "ISO-3166");
#    }

    _xmlset($customer_xml, "root/customer/customercontactdetails/contactname", "");
    _xmlset($customer_xml, "root/customer/customercontactdetails/contactperson", $Customer->{'FullName'});
    _xmlset($customer_xml, "root/customer/customercontactdetails/contactpersonemail", $Customer->{'EMail'});
    _xmlset($customer_xml, "root/customer/customercontactdetails/contactpersonphone", $Customer->{'Phone'});

#    _xmlset($customer_xml, "root/customer/customeradditionalinformation/comment", $Customer->{'Comment'});
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/customeragreementidentifier", "");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/customerreferencenumber", "");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/directdebitbankaccount", "");
 
	_xmlset($customer_xml, 			"root/customer/customeradditionalinformation/invoicinglanguage", "FI");
	_xmlSetAttribute($customer_xml, "root/customer/customeradditionalinformation/invoicinglanguage", "type", "ISO-3166");
	
#    _xmlset($customer_xml, 			"root/customer/customeradditionalinformation/invoiceprintchannelformat", "");
#    _xmlSetAttribute($customer_xml, "root/customer/customeradditionalinformation/invoiceprintchannelformat", "type", "netvisor");

#    _xmlset($customer_xml, "root/customer/customeradditionalinformation/yourdefaultreference", "");
#    _xmlset($customer_xml, "root/customer/customeradditionalinformation/defaulttextbeforeinvoicelines", "");
#    _xmlset($customer_xml, "root/customer/customeradditionalinformation/defaulttextafterinvoicelines", "");
#    _xmlset($customer_xml, "root/customer/customeradditionalinformation/defaultsalesperson/salespersonid", "");
#    _xmlSetAttribute($customer_xml, "root/customer/customeradditionalinformation/defaultsalesperson/salespersonid", "type", "netvisor");

    my $data = $customer_xml->findnodes_as_string('root');
    my $response = $self->SUPER::request("customer.nv", "POST", $data, "?method=$postMethod");
    GetLog->debug("Response from API: $response->[1]");
    
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
    my $Order = shift;
    my $Customer = shift;
    my $InvoiceType = shift;
    my $postMethod = shift;
    my $id = shift; # NetvisorKey

#    my $LineItems = $LineItemContainer->{'LineItems'};
    my $IsDelivered = undef;
    my $VATCode;

    if(defined $Order->{'DispatchedOn'} or $Order->{'ShippedOn'}) {
        $IsDelivered = 'delivered';
    } else {
        $IsDelivered = 'undelivered';
    }

    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $invoice_xml = XML::XPath->new(context => $RootNode);
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicenumber", $Order->{'Alias'});
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicedate", $Order->{'CreationDate'}->strftime("%Y-%m-%d"));
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicedate", "format", "ansi");
    
    if(defined $Order->{'PaidOn'}) {
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoicevaluedate", $Order->{'PaidOn'}->strftime("%Y-%m-%d")); 
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicevaluedate", "format", "ansi");
    }

    if(defined $Order->{'InvoicedOn'}) {
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoicedeliverydate", $Order->{'InvoicedOn'}->strftime("%Y-%m-%d"));
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicedeliverydate", "format", "ansi");
    }

    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicereferencenumber", $Order->{'ReferenceNumber'});
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceamount", $LineItemContainer->{'GrandTotal'});
    #_xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceamount", "iso4217currencycode", $LineItemContainer->{'CurrencyID'});
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceamount", "currencyrate", "0,00");
    _xmlset($invoice_xml, "root/salesinvoice/selleridentifier", "");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/selleridentifier", "type", "netvisor");
    _xmlset($invoice_xml, "root/salesinvoice/sellername", "Myyjä");
    _xmlset($invoice_xml, "root/salesinvoice/invoicetype", $InvoiceType);
    
	if(defined $Order->{'InvoicedOn'}) {
		_xmlset($invoice_xml, "root/salesinvoice/salesinvoicestatus", "open");    
	} else {
		_xmlset($invoice_xml, "root/salesinvoice/salesinvoicestatus", "unsent");
	}


    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicestatus", "type", "netvisor");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicefreetextbeforelines", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicefreetextafterlines", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceourreference", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceyourreference", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceprivatecomment", "testimeininkiä");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomeridentifier", $Customer->{'Alias'} );
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicingcustomeridentifier", "type", "customer");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomername", $Customer->{'FullName'});
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomernameextension", $Customer->{'JobTitle'});
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomeraddressline", $Customer->{'BillingAddress'}->{'Street'});
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomerpostnumber", $Customer->{'BillingAddress'}->{'Zipcode'});
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomertown", $Customer->{'BillingAddress'}->{'City'});
#    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomercountrycode", $Customer->{'BillingAddress')->{'CountryCode')->{'Code2'});
#    _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicingcustomercountrycode", "type", "ISO 3316");
    
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddressname", $Customer->{'BillingAddress'}->{'FullName'});
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddressline", $Customer->{'BillingAddress'}->{'Street'});
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresspostnumber", $Customer->{'BillingAddress'}->{'Zipcode'});
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresstown", $Customer->{'BillingAddress'}->{'City'});
#        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresscountrycode", $Customer->{'BillingAddress')->{'CountryCode')->{'Code2'});
 
 #   _xmlSetAttribute($invoice_xml, "root/salesinvoice/deliveryaddresscountrycode", "type", "ISO 3316");
#    _xmlset($invoice_xml, "root/salesinvoice/deliverymethod", $LineItemContainer->{'LineItemShipping')->{'NameOrAlias', $LanguageID));
    _xmlset($invoice_xml, "root/salesinvoice/deliveryterm", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicetaxhandlingtype", "countrygroup");
#    _xmlset($invoice_xml, "root/salesinvoice/paymenttermnetdays", $Shop->{'NetvisorDefaultDueDate'));
    _xmlset($invoice_xml, "root/salesinvoice/paymenttermcashdiscountdays", "");
    _xmlset($invoice_xml, "root/salesinvoice/paymenttermcashdiscount", "");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/paymenttermcashdiscount", "type", "percentage");
    _xmlset($invoice_xml, "root/salesinvoice/expectpartialpayments", "0");
    _xmlset($invoice_xml, "root/salesinvoice/trydirectdebitlink", "");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/trydirectdebitlink", "mode", "ignore_error");
    _xmlset($invoice_xml, "root/salesinvoice/overridevouchersalesreceivablesaccountnumber", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceagreementidentifier", "");
    _xmlset($invoice_xml, "root/salesinvoice/printchannelformat", "");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/printchannelformat", "type", "netvisor");
    _xmlset($invoice_xml, "root/salesinvoice/secondname", "");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/secondname", "type", "netvisor");
    
#    foreach my $LineItem (@$LineItems) {
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", $LineItem->{'Product')->{'Alias'));
#        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "customer");
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname", $LineItem->{'Product'}->{'NameOrAlias'});
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", $LineItem->{'BasePrice'));
#        if($LineItemContainer->{'TaxModel') == 0) {
#            _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");
#        } else {
#            _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "gross");
#        }
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitpurchaseprice", "");
#        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitpurchaseprice", "type", "gross");
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", $LineItem->{'TaxRate') * 100);
#        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "vatcode", $VATCode);
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity", $LineItem->{'Quantity'));
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinediscountpercentage", "");
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinefreetext", "");
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinevatsum", "");
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinesum", "");
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/accountingaccountsuggestion", "");
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/skipaccrual", "");
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionname", "Testi dimensio");
#        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionitem", "Testi dimension item");
#        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionitem", "integrationdimensiondetailguid", "1");
#    }

    #_xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoicecommentline", "Testilasku");
    #_xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/linesum", "100");
    #_xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/linesum", "type", "net");
    #_xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/description", "");
    #_xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/accountnumber", "3000");
    #_xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/vatpercent", "22");
    #_xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/vatpercent", "vatcode", "KOMY");
    #_xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/skipaccrual", "0");
    #_xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/dimension/dimensionname", "Testi dimensio");
    #_xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/dimension/dimensionitem", "Testi dimension item");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/overridedefaultsalesaccrualaccountnumber", "0");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/salesinvoiceaccrualtype", "");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/accrualvoucherentry/month", "1");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/accrualvoucherentry/year", "2018");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/accrualvoucherentry/sum", "100");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/mimetype", "Application/pdf");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/attachmentdescription", "testi");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/filename", "testi.pdf");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/documentdata", "");
    #_xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/documentdata", "type", "pdf");
    #_xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/printbydefault", "1");
    #_xmlset($invoice_xml, "root/salesinvoice/customtags/tag/tagname", "testitagi");
    #_xmlset($invoice_xml, "root/salesinvoice/customtags/tag/tagvalue", "2018-01-08");
    #_xmlSetAttribute($invoice_xml, "root/salesinvoice/customtags/tag/tagvalue", "datatype", "date");

    my $data = $invoice_xml->findnodes_as_string('root');
    my $response = $self->SUPER::request("salesinvoice.nv", "POST", $data, "?method=$postMethod");
    GetLog->debug("Response from API: $response->[1]");
    return $response;

}

#=============================================================================
# §function     GetProductList
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  gets product list from API
#-----------------------------------------------------------------------------
# §input
# §return       $hResults | hash with products' data | hash
#=============================================================================
sub GetProductList {
    my $self = shift;

    my $hResults = $self->SUPER::request("productlist.nv", "GET");

    return $hResults;
}

#=============================================================================
# §function     GetProductDetails
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  gets product details from API
#-----------------------------------------------------------------------------
# §input        $productId | Netvisor product id | string
# §return       $hResults | hash with product's details | hash
#=============================================================================
sub GetProductDetails {
    my $self = shift;
    my $hProductList = $self->GetProductList();

    my $productId;
    # TODO get productId from ProductList
    my $hResults = $self->SUPER::request("getproduct.nv?idlist=1,2,3,4", "GET");

    return $hResults;
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

#    my $SuperProduct;

    # check if sub product or master
 #   if (!defined $Product->{'SuperProduct')) {
#        $Price = $Product->{'ListPrices')->[0]->{'ListPrice'};
#    } else {
#        $SuperProduct = $Product->{'SuperProduct');
#        $Price = $SuperProduct->{'ListPrices')->[0]->{'ListPrice'};
#    }

    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $product_xml = XML::XPath->new(context => $RootNode);
    _xmlset($product_xml, "root/product/productbaseinformation/productcode", $Product->{'Alias'});
    _xmlset($product_xml, "root/product/productbaseinformation/productgroup", $Product->{'Class'});
    _xmlset($product_xml, "root/product/productbaseinformation/name", $Product->{'NameOrAlias'});
    _xmlset($product_xml, "root/product/productbaseinformation/description", $Product->{'Description'});
    _xmlset($product_xml, "root/product/productbaseinformation/unitprice", $Product->{'Price'});
    _xmlSetAttribute($product_xml, "root/product/productbaseinformation/unitprice", "type", "net");
    
 #   if (defined $Product->{'OrderUnit')) {
 #       _xmlset($product_xml, "root/product/productbaseinformation/unit", $Product->{'OrderUnit')->{'NameOrAlias', $LanguageID));
 #   }

#    _xmlset($product_xml, "root/product/productbaseinformation/unitweight", $Product->{'Weight'));
#    _xmlset($product_xml, "root/product/productbaseinformation/purchaseprice", "");
    _xmlset($product_xml, "root/product/productbaseinformation/tariffheading", $Product->{'NameOrAlias'});
 #   _xmlset($product_xml, "root/product/productbaseinformation/comissionpercentage", "");
    _xmlset($product_xml, "root/product/productbaseinformation/isactive", $Product->{'IsAvailable'});
    _xmlset($product_xml, "root/product/productbaseinformation/issalesproduct", "1");
    _xmlset($product_xml, "root/product/productbaseinformation/inventoryenabled", "0");
    _xmlset($product_xml, "root/product/productbookkeepingdetails/defaultvatpercentage", "0");
    my $data = $product_xml->findnodes_as_string('root');
    my $response = $self->SUPER::request("product.nv", "POST", $data, "?method=$postMethod&id=$id");

    $self->PostWarehouseEvent($Product);

    return $response;
}


#=============================================================================
# §function     GetDimensionList
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  gets dimension list from API
#-----------------------------------------------------------------------------
# §input        $showHidden | when '1' then also hidden dimensions are returned
#               in response | string
# §return       $hDimensions | hash with dimensions' data | hash
#=============================================================================
sub GetDimensionList {
    my $self = shift;
    my $showHidden = shift;

    my $response = $self->SUPER::request("dimensionlist.nv", "GET", undef, "?showhidden=$showHidden");
    my $hDimensions = $self->_xml2hash($response->[0]);

    return $hDimensions;
}

#=============================================================================
# §function     PostDimension
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  sends dimension to Netvisor
#-----------------------------------------------------------------------------
# §input        $postMethod | XML determines where new dimension is added in
#               hierarchy or which dimension to edit ('edit' or 'add') | string
# §input        $postAsChild | determines if dimension is posted as child in
#               dimension hierarchy ('0' or '1') | string
# $input        $fatherId | if posted as child, father id is mandatory | string
# §input        $fatherName | if posted as child, father name is mandatory | string
# §return
#=============================================================================
sub PostDimension {
    my $self = shift;
    my $postMethod = shift;
    my $postAsChild = shift;
    my $fatherId = shift;
    my $fatherName = shift;

    if($postAsChild eq "1") {
        if(!defined $fatherId and $fatherName) {
            GetLog->debug("fatherId and fatherName are mandatory");
            return;
        }
    }

    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $dimension_xml = XML::XPath->new(context => $RootNode);
    _xmlset($dimension_xml, "root/dimensionitem/name", "Testi dimensio");
    _xmlset($dimension_xml, "root/dimensionitem/item", "new Testi item's child");

    if($postMethod eq "edit") {
        _xmlset($dimension_xml, "root/dimensionitem/olditem", "Testi item");
    }

    if($postAsChild eq "1") {
        _xmlset($dimension_xml, "root/dimensionitem/fatherid", $fatherId);
        _xmlset($dimension_xml, "root/dimensionitem/fatheritem", $fatherName);
    }

    my $data = $dimension_xml->findnodes_as_string('root');
    my $response = $self->SUPER::request("dimensionitem.nv", "POST", $data, "?method=$postMethod");

    return $response;

}
#=============================================================================
# §function     DeleteDimension
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  deletes requested dimension
#-----------------------------------------------------------------------------
# §input        $dimensionName | parent dimension of the dimension which to
#               delete | string
# §input        $dimensionSubName | name of the dimension to delete | string
# §return
#=============================================================================
sub DeleteDimension {
    my $self = shift;
    my $dimensionName = shift;
    my $dimensionSubName = shift;

    my $response = $self->SUPER::request("dimensiondelete.nv", "POST", undef, "?dimensionname=$dimensionName&dimensionsubname=$dimensionSubName");

    return $response;

}

#=============================================================================
# §function     _getAuthData
# §state        private
#-----------------------------------------------------------------------------
# §syntax       my $hAuth = $self->_setAuthData($Shop);
#-----------------------------------------------------------------------------
# §description  Gets authentication data for REST calls
#-----------------------------------------------------------------------------
# §input        $Shop  | shop object | object
# §return       $hAuth | hash with the athentication data | hash
#=============================================================================
sub _getAuthData {
    my $self = shift;

    my $UserId = config->{'NetvisorRESTUserId'};
    my $Key = config->{'NetvisorRESTKey'};
    my $CompanyId = config->{'NetvisorShopVATID'};
    my $PartnerId = config->{'Netvisor_PartnerId'};
    my $PartnerKey = config->{'Netvisor_PartnerKey'};
    my $hAuth = {
        UserId => $UserId,
        Key => $Key,
        CompanyId => $CompanyId,
        PartnerId => $PartnerId,
        PartnerKey => $PartnerKey,
    };

    return $hAuth;
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


sub _xmlSetAttribute {
    my $Tree = shift;
    my $xpath = shift;
    my $AttributeKey = shift;
    my $AttributeValue = shift;

    if(!$Tree->exists($xpath)) {
        $Tree->createNode($xpath);
    }
    my $Node = $Tree->find($xpath)->get_node(1);
    my $AttributeNode = XML::XPath::Node::Attribute->new($AttributeKey, $AttributeValue, '');
    $Node->appendAttribute($AttributeNode);
}


sub _xml2hash {
    my $self = shift;
    my $xmlString = shift;

    return XMLin($xmlString);
}


1;
