package Requests;
use base RESTClient;

#use strict;
use warnings;

use Data::Dumper;
use DateTime;
use XML::XPath;
use Dancer ':syntax';
use XML::Simple;
use XML::LibXML::SAX;

sub new {
    my $class = shift;

    my $Url = config->{'Netvisor_RESTTestUrl'};
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
    my $Order = shift;
    my $postMethod = shift;

    my $LanguageID = 'FI';
    my $Customer = shift;
    my $BillingAddress = $Customer->get('BillingAddress');
    my $ShippingAddress; #$Order->get('ShippingAddress');
    
    # Create XML for post
    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $customer_xml = XML::XPath->new(context => $RootNode);
    _xmlset($customer_xml, "root/customer/customerbaseinformation/internalidentifier", $Customer->get('Alias'));
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/externalidentifier", $BillingAddress->get('VATID'));
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/organizationunitnumber", "");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/name", $BillingAddress->get('FullName'));
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/nameextension", $BillingAddress->get('JobTitle'));
    _xmlset($customer_xml, "root/customer/customerbaseinformation/streetaddress", $BillingAddress->get('Street'));
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/additionaladdressline", $BillingAddress->get('Street2'));
    _xmlset($customer_xml, "root/customer/customerbaseinformation/city", $BillingAddress->get('City'));
    _xmlset($customer_xml, "root/customer/customerbaseinformation/postnumber", $BillingAddress->get('Zipcode'));
#   _xmlset($customer_xml, "root/customer/customerbaseinformation/country", $BillingAddress->get('Country')->{'Code2'});
#    _xmlSetAttribute($customer_xml, "root/customer/customerbaseinformation/country", "type", "ISO-3166");
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/customergroupname", config->{'netvisor_customergroupname'} );
    _xmlset($customer_xml, "root/customer/customerbaseinformation/phonenumber", $BillingAddress->get('Phone'));
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/faxnumber", $BillingAddress->get('Fax'));
    _xmlset($customer_xml, "root/customer/customerbaseinformation/email", $BillingAddress->get('EMail'));
#    _xmlset($customer_xml, "root/customer/customerbaseinformation/homepageuri", $BillingAddress->get('URL'));
    _xmlset($customer_xml, "root/customer/customerbaseinformation/isactive", "1");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/isprivatecustomer", "1");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/emailinvoicingaddress", $BillingAddress->get('EMail'));

#    _xmlset($customer_xml, "root/customer/customerfinvoicedetails/finvoiceaddress", $Customer->get('NetvisorEInvoiceAddress'));
#    _xmlset($customer_xml, "root/customer/customerfinvoicedetails/finvoiceroutercode", $Customer->get('NetvisorEInvoiceOperatorAddress'));

    if(defined $ShippingAddress) {
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliveryname", $ShippingAddress->get('FullName'));
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverystreetaddress", $ShippingAddress->get('Street'));
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverycity", $ShippingAddress->get('City'));
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverypostnumber", $ShippingAddress->get('Zipcode'));
#        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverycountry", $ShippingAddress->get('Country')->{'Code2'});
#        _xmlSetAttribute($customer_xml, "root/customer/customerdeliverydetails/deliverycountry", "type", "ISO-3166");
    } else {
        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliveryname", $BillingAddress->get('FullName'));
        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverystreetaddress", $BillingAddress->get('Street'));
        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverycity", $BillingAddress->get('City'));
        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverypostnumber", $BillingAddress->get('Zipcode'));
        _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverycountry", $BillingAddress->get('Country')->{'Code2'});
        _xmlSetAttribute($customer_xml, "root/customer/customerdeliverydetails/deliverycountry", "type", "ISO-3166");
    }

    _xmlset($customer_xml, "root/customer/customercontactdetails/contactname", "");
    _xmlset($customer_xml, "root/customer/customercontactdetails/contactperson", $BillingAddress->get('FullName'));
    _xmlset($customer_xml, "root/customer/customercontactdetails/contactpersonemail", $BillingAddress->get('EMail'));
    _xmlset($customer_xml, "root/customer/customercontactdetails/contactpersonphone", $BillingAddress->get('Phone'));

    _xmlset($customer_xml, "root/customer/customeradditionalinformation/comment", $Customer->get('Comment'));
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/customeragreementidentifier", "");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/customerreferencenumber", "");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/directdebitbankaccount", "");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/invoicinglanguage", "");
    _xmlSetAttribute($customer_xml, "root/customer/customeradditionalinformation/invoicinglanguage", "type", "ISO-3166");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/invoiceprintchannelformat", "");
    _xmlSetAttribute($customer_xml, "root/customer/customeradditionalinformation/invoiceprintchannelformat", "type", "netvisor");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/yourdefaultreference", "");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/defaulttextbeforeinvoicelines", "");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/defaulttextafterinvoicelines", "");
    _xmlset($customer_xml, "root/customer/customeradditionalinformation/defaultsalesperson/salespersonid", "");
    _xmlSetAttribute($customer_xml, "root/customer/customeradditionalinformation/defaultsalesperson/salespersonid", "type", "netvisor");

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

    my $Shop = $Order->get('Site');
    my $LanguageID = $Shop->get('LanguageID');
    my $LineItemContainer = $Order->get('LineItemContainer');
    my $LineItems = $LineItemContainer->get('LineItems');
    my $IsDelivered = undef;
    my $VATCode;

    if(defined $Order->get('DispatchedOn') or $Order->get('ShippedOn')) {
        $IsDelivered = 'delivered';
    } else {
        $IsDelivered = 'undelivered';
    }

    if($LineItemContainer->get('TaxArea')->{'Alias'} eq "EU") {
        if(defined $LineItemContainer->get('TaxAreaDigital') and $LineItemContainer->get('TaxAreaDigital')->{'CountryID'} == 246) {
            $VATCode = "KOMY";
        } else {
            $VATCode = "EUMY";
        }
    } else {
        $VATCode = "EUUM";
    }

    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $invoice_xml = XML::XPath->new(context => $RootNode);
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicenumber", $Order->get('Alias'));
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicedate", $Order->get('CreationDate')->strftime("%Y-%m-%d"));
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicedate", "format", "ansi");
<<<<<<< HEAD
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicevaluedate", ""); 
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicevaluedate", "format", "ansi");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicedeliverydate", "");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicedeliverydate", "format", "ansi");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicereferencenumber", "123456");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceamount", "123,34");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceamount", "iso4217currencycode", "EUR");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceamount", "currencyrate", "");
=======
    
    if(defined $Order->get('PaidOn')) {
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoicevaluedate", $Order->get->('PaidOn')->strftime("%Y-%m-%d")); 
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicevaluedate", "format", "ansi");
    }

    if(defined $Order->get('InvoicedOn')) {
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoicedeliverydate", $Order->get('InvoicedOn')->strftime("%Y-%m-%d"));
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicedeliverydate", "format", "ansi");
    }

    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicereferencenumber", $Order->get('ReferenceNumber'));
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceamount", $LineItemContainer->get('GrandTotal'));
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceamount", "iso4217currencycode", $LineItemContainer->get('CurrencyID'));
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceamount", "currencyrate", "0,00");
>>>>>>> b607578fc35e0c456cc180bbfbe455fc15297d10
    _xmlset($invoice_xml, "root/salesinvoice/selleridentifier", "");
    _xmlSetAttribute("$invoice_xml", "root/salesinvoice/selleridentifier", "type", "netvisor");
    _xmlset($invoice_xml, "root/salesinvoice/sellername", "Myyjä");
    _xmlset($invoice_xml, "root/salesinvoice/invoicetype", $InvoiceType);
    
    if($InvoiceType eq "Order") {
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoicestatus", $IsDelivered);
    } else {
        if(defined $Order->get('InvoicedOn')) {
            _xmlset($invoice_xml, "root/salesinvoice/salesinvoicestatus", "open");    
        } else {
            _xmlset($invoice_xml, "root/salesinvoice/salesinvoicestatus", "unsent");
        }
    }

    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicestatus", "type", "netvisor");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicefreetextbeforelines", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicefreetextafterlines", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceourreference", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceyourreference", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceprivatecomment", "testimeininkiä");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomeridentifier", $Customer->get('Alias'));
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicingcustomeridentifier", "type", "customer");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomername", $Customer->get('FullName'));
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomernameextension", $Customer->get('JobTitle'));
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomeraddressline", $Customer->get('BillingAddress')->get('Street'));
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomeradditionaladdressline", $Customer->get('BillingAddress')->get('Street2'));
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomerpostnumber", $Customer->get('BillingAddress')->get('Zipcode'));
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomertown", $Customer->get('BillingAddress')->get('City'));
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomercountrycode", $Customer->get('BillingAddress')->get('CountryCode')->{'Code2'});
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicingcustomercountrycode", "type", "ISO 3316");
    
    if(defined $Order->get('ShippingAddress')) {
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddressname", $Order->get('ShippingAddress')->get('FullName'));
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddressline", $Order->get('ShippingAddress')->get('Street'));
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresspostnumber", $Order->get('ShippingAddress')->get('Zipcode'));
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresstown", $Order->get('ShippingAddress')->get('City'));
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresscountrycode", $Order->get('ShippingAddress')->get('CountryCode')->{'Code2'});
    } else {
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddressname", $Customer->get('BillingAddress')->get('FullName'));
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddressline", $Customer->get('BillingAddress')->get('Street'));
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresspostnumber", $Customer->get('BillingAddress')->get('Zipcode'));
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresstown", $Customer->get('BillingAddress')->get('City'));
        _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresscountrycode", $Customer->get('BillingAddress')->get('CountryCode')->{'Code2'});
    }

    _xmlSetAttribute($invoice_xml, "root/salesinvoice/deliveryaddresscountrycode", "type", "ISO 3316");
    _xmlset($invoice_xml, "root/salesinvoice/deliverymethod", $LineItemContainer->get('LineItemShipping')->get('NameOrAlias', $LanguageID));
    _xmlset($invoice_xml, "root/salesinvoice/deliveryterm", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicetaxhandlingtype", "countrygroup");
    _xmlset($invoice_xml, "root/salesinvoice/paymenttermnetdays", $Shop->get('NetvisorDefaultDueDate'));
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
    
    foreach my $LineItem (@$LineItems) {
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", $LineItem->get('Product')->get('Alias'));
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "customer");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname", $LineItem->get('Product')->get('NameOrAlias'));
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", $LineItem->get('BasePrice'));
        if($LineItemContainer->get('TaxModel') == 0) {
            _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");
        } else {
            _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "gross");
        }
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitpurchaseprice", "");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitpurchaseprice", "type", "gross");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", $LineItem->get('TaxRate') * 100);
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "vatcode", $VATCode);
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity", $LineItem->get('Quantity'));
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinediscountpercentage", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinefreetext", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinevatsum", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinesum", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/accountingaccountsuggestion", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/skipaccrual", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionname", "Testi dimensio");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionitem", "Testi dimension item");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionitem", "integrationdimensiondetailguid", "1");
    }

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

    my $Shop = $Product->get('Site');
    my $LanguageID = $Shop->get('LanguageID');
    my $Price;
    my $SuperProduct;

    # check if sub product or master
    if (!defined $Product->get('SuperProduct')) {
        $Price = $Product->get('ListPrices')->[0]->{'ListPrice'};
    } else {
        $SuperProduct = $Product->get('SuperProduct');
        $Price = $SuperProduct->get('ListPrices')->[0]->{'ListPrice'};
    }

    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $product_xml = XML::XPath->new(context => $RootNode);
    _xmlset($product_xml, "root/product/productbaseinformation/productcode", $Product->get('Alias'));
    _xmlset($product_xml, "root/product/productbaseinformation/productgroup", $Product->get('Class')->get('Alias'));
    _xmlset($product_xml, "root/product/productbaseinformation/name", $Product->get('NameOrAlias', $LanguageID));
    _xmlset($product_xml, "root/product/productbaseinformation/description", $Product->get('Description', $LanguageID));
    _xmlset($product_xml, "root/product/productbaseinformation/unitprice", $Price);
    _xmlSetAttribute($product_xml, "root/product/productbaseinformation/unitprice", "type", "net");
    
    if (defined $Product->get('OrderUnit')) {
        _xmlset($product_xml, "root/product/productbaseinformation/unit", $Product->get('OrderUnit')->get('NameOrAlias', $LanguageID));
    }

    _xmlset($product_xml, "root/product/productbaseinformation/unitweight", $Product->get('Weight'));
    _xmlset($product_xml, "root/product/productbaseinformation/purchaseprice", "");
    _xmlset($product_xml, "root/product/productbaseinformation/tariffheading", $Product->get('NameOrAlias', $LanguageID));
    _xmlset($product_xml, "root/product/productbaseinformation/comissionpercentage", "");
    _xmlset($product_xml, "root/product/productbaseinformation/isactive", $Product->get('IsAvailable'));
    _xmlset($product_xml, "root/product/productbaseinformation/issalesproduct", "1");
    _xmlset($product_xml, "root/product/productbaseinformation/inventoryenabled", "1");
    _xmlset($product_xml, "root/product/productbookkeepingdetails/defaultvatpercentage", "24");
    my $data = $product_xml->findnodes_as_string('root');
    my $response = $self->SUPER::request("product.nv", "POST", $data, "?method=$postMethod&id=$id");

    $self->PostWarehouseEvent($Product);

    return $response;
}

#=============================================================================
# §function     PostWarehouseEvent
# §state        public
#-----------------------------------------------------------------------------
# §syntax
#-----------------------------------------------------------------------------
# §description  Imports warehouse event to Netvisor
#-----------------------------------------------------------------------------
# §input        $Product | product | object
# §return
#=============================================================================
sub PostWarehouseEvent {
    my $self = shift;
    my $Product = shift;

    my $Price;
    my $SuperProduct;
    # check if sub product or master
    if (!defined $Product->get('SuperProduct')) {
        $Price = $Product->get('ListPrices')->[0]->{'ListPrice'};
    } else {
        $SuperProduct = $Product->get('SuperProduct');
        $Price = $SuperProduct->get('ListPrices')->[0]->{'ListPrice'};
    }

    my $time = DateTime->now();
    my $FormattedDate = $time->strftime("%Y-%m-%d");

    my $RootNode = XML::XPath::Node::Element->new('root', "");
    my $warehouse_xml = XML::XPath->new(context => $RootNode);
    _xmlset($warehouse_xml, "root/warehouseevent/description", "");
    _xmlset($warehouse_xml, "root/warehouseevent/reference", $Product->get('ObjectID'));
    _xmlset($warehouse_xml, "root/warehouseevent/deliverymethod", "");
    _xmlset($warehouse_xml, "root/warehouseevent/distributer", "");
    _xmlSetAttribute($warehouse_xml, "root/warehouseevent/distributer", "type", "customer");
    _xmlset($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/eventtype", "Hankinta"); 
    _xmlSetAttribute($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/eventtype", "type", "customer");
    _xmlset($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/product", $Product->get('Alias'));
    _xmlSetAttribute($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/product", "type", "customer");
    _xmlset($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/inventoryplace", "Testivarasto");
    _xmlset($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/description", "testausta");
    _xmlset($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/quantity", $Product->get('StockLevel'));
    _xmlset($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/unitprice", $Price);
    _xmlset($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/valuedate", $FormattedDate);
    _xmlSetAttribute($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/valuedate", "format", "ansi");
    _xmlset($warehouse_xml, "root/warehouseevent/warehouseeventlines/warehouseeventline/status", "open");
    my $data = $warehouse_xml->findnodes_as_string('root');
    my $response = $self->SUPER::request("warehouseevent.nv", "POST", $data);

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
<<<<<<< HEAD
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
=======
sub _getAuthData {
    my $self = shift;
>>>>>>> b607578fc35e0c456cc180bbfbe455fc15297d10

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
