package Requests;
use base RESTClient;

#use strict;
#use warnings;

use Data::Dumper;
use XML::XPath;
#use XML::Simple;
#use XML::LibXML::SAX;
use Dancer ':syntax';


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
# §input        $postMethod | post method, can be 'Add' or 'Edit' | string
# §return
#=============================================================================
sub PostCustomer {
    my $self = shift;
    #my $Order = shift;
    my $postMethod = shift;
	my $myplayer = shift;
	
    # Create XML to post
    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $customer_xml = XML::XPath->new(context => $RootNode);
    _xmlset($customer_xml, "root/customer/customerbaseinformation/internalidentifier", "123465");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/externalidentifier", "123456-7");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/organizationunitnumber", "");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/name", $myplayer->first + " " + $myplayer->last );
    _xmlset($customer_xml, "root/customer/customerbaseinformation/nameextension", "Herra");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/streetaddress", "Testikatu 1");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/additionaladdressline", "");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/city", "Tampere");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/postnumber", "33100");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/country", "FI");
    _xmlSetAttribute($customer_xml, "root/customer/customerbaseinformation/country", "type", "ISO-3166");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/customergroupname", "Asiakasryhmä 1");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/phonenumber", "0501234567");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/faxnumber", "");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/email", 'testi.mies@testi.fi');
    _xmlset($customer_xml, "root/customer/customerbaseinformation/homepageuri", "");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/isactive", "1");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/isprivatecustomer", "1");
    _xmlset($customer_xml, "root/customer/customerbaseinformation/emailinvoicingaddress", 'testi.mies@testi.fi');

    _xmlset($customer_xml, "root/customer/customerfinvoicedetails/finvoiceaddress", "");
    _xmlset($customer_xml, "root/customer/customerfinvoicedetails/finvoiceroutercode", "");

    _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliveryname", "Testi Mies");
    _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverystreetaddress", "Testikatu 1");
    _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverycity", "Tampere");
    _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverypostnumber", "33100");
    _xmlset($customer_xml, "root/customer/customerdeliverydetails/deliverycountry", "FI");
    _xmlSetAttribute($customer_xml, "root/customer/customerdeliverydetails/deliverycountry", "type", "ISO-3166");

    _xmlset($customer_xml, "root/customer/customercontactdetails/contactname", "");
    _xmlset($customer_xml, "root/customer/customercontactdetails/contactperson", "Testi Mies");
    _xmlset($customer_xml, "root/customer/customercontactdetails/contactpersonemail", 'testi.mies@testi.fi');
    _xmlset($customer_xml, "root/customer/customercontactdetails/contactpersonphone", "0501234567");

    _xmlset($customer_xml, "root/customer/customeradditionalinformation/comment", "");
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
# $input        $postMethod | 'Add' or 'Edit' | string
# §input        $id | if $postMethod == 'Edit', invoice's id is needed | string
# §return       
#=============================================================================
sub PostSalesInvoice {
    my $self = shift;
    my $Order = shift;
    my $InvoiceType = shift;
    my $postMethod = shift;
    my $id = shift; # NetvisorKey

    my $Shop = $Order->get('Site');
    my $LineItemContainer = $Order->get('LineItemContainer');
    my $IsDelivered;

    if(defined $Order->get('DispatchedOn') or $Order->get('ShippedOn')) {
        $IsDelivered = 'delivered';
    } else {
        $IsDelivered = 'undelivered';
    }

    my $RootNode = XML::XPath::Node::Element->new('root',"");
    my $invoice_xml = XML::XPath->new(context => $RootNode);
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicenumber", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicedate", "2018-01-08");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicedate", "format", "ansi");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicevaluedate", ""); 
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicevaluedate", "format", "ansi");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicedeliverydate", "");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicedeliverydate", "format", "ansi");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicereferencenumber", "123456");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceamount", "123,34");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceamount", "iso4217currencycode", "EUR");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceamount", "currencyrate", "");
    _xmlset($invoice_xml, "root/salesinvoice/selleridentifier", "");
    _xmlSetAttribute("$invoice_xml", "root/salesinvoice/selleridentifier", "type", "netvisor");
    _xmlset($invoice_xml, "root/salesinvoice/sellername", "Myyjä");
    _xmlset($invoice_xml, "root/salesinvoice/invoicetype", $InvoiceType);
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicestatus", "Open");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoicestatus", "netvisor");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicefreetextbeforelines", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicefreetextafterlines", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceourreference", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceyourreference", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceprivatecomment", "testimeininkiä");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomeridentifier", "123465");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicingcustomeridentifier", "type", "netvisor");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomername", "Testi Mies");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomernameextension", "Herra");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomeraddressline", "Testikatu 1");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomeradditionaladdressline", "");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomerpostnumber", "33100");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomertown", "Tampere");
    _xmlset($invoice_xml, "root/salesinvoice/invoicingcustomercountrycode", "FI");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicingcustomercountrycode", "type", "ISO 3316");
    _xmlset($invoice_xml, "root/salesinvoice/deliveryaddressname", "Testi Mies");
    _xmlset($invoice_xml, "root/salesinvoice/deliveryaddressline", "Testikatu 1");
    _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresspostnumber", "33100");
    _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresstown", "Tampere");
    _xmlset($invoice_xml, "root/salesinvoice/deliveryaddresscountrycode", "FI");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/deliveryaddresscountrycode", "type", "ISO 3316");
    _xmlset($invoice_xml, "root/salesinvoice/deliverymethod", "Polkupyörä");
    _xmlset($invoice_xml, "root/salesinvoice/deliveryterm", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoicetaxhandlingtype", "countrygroup");
    _xmlset($invoice_xml, "root/salesinvoice/paymenttermnetdays", "14");
    _xmlset($invoice_xml, "root/salesinvoice/paymenttermcashdiscountdays", "");
    _xmlset($invoice_xml, "root/salesinvoice/paymenttermcashdiscount", "");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/paymenttermcashdiscount", "type", "percentage");
    _xmlset($invoice_xml, "root/salesinvoice/expectpartialpayments", "0");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/expectpartialpayments", "mode", "ignore_error");
    _xmlset($invoice_xml, "root/salesinvoice/overridevouchersalesreceivablesaccountnumber", "");
    _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceagreementidentifier", "");
    _xmlset($invoice_xml, "root/salesinvoice/printchannelformat", "");
    _xmlSetAttribute($invoice_xml, "root/salesinvoice/printchannelformat", "type", "netvisor");
        _xmlset($invoice_xml, "root/salesinvoice/secondname", "");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/secondname", "type", "netvisor");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "1234");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "customer");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname", "testituote");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "123,50");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitpurchaseprice", "50,00");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitpurchaseprice", "type", "net");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "22");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "vatcode", "KOMY");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity", "2");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinediscountpercentage", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinefreetext", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinevatsum", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinesum", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/accountingaccountsuggestion", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/skipaccrual", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimension/dimensionname", "Testi dimensio");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/dimansion/dimensionitem", "Testi dimension item");
        _xmlset($invoice_xml, "root/salesinvoice/invoicelines/invoiceline/salesinvoicecommentline/comment", "Testilasku");
        _xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/linesum", "100");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/linesum", "type", "net");
        _xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/description", "");
        _xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/accountnumber", "3000");
        _xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/vatpercentage", "22");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/vatpercentage", "vatcode", "KOMY");
        _xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/skipaccrual", "0");
        _xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/dimension/dimensionname", "Testi dimensio");
        _xmlset($invoice_xml, "root/salesinvoice/invoicevoucherlines/voucherline/dimension/dimensionitem", "Testi dimension item");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/overridedefaultsalesaccrualaccountnumber", "");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/salesinvoiceaccrualtype", "");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/accrualvoucherentry/month", "1");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/accrualvoucherentry/year", "2018");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceaccrual/accrualvoucherentry/sum", "100");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/mimetype", "Application/pdf");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/attachmentdescription", "testi");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/filename", "testi.pdf");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/documentdata", "");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/documentdata", "type", "pdf");
        _xmlset($invoice_xml, "root/salesinvoice/salesinvoiceattachments/salesinvoiceattachment/printbydefault", "1");
        _xmlset($invoice_xml, "root/salesinvoice/customtags/tag/tagname", "testitagi");
        _xmlset($invoice_xml, "root/salesinvoice/customtags/tag/tagvalue", "2018-01-08");
        _xmlSetAttribute($invoice_xml, "root/salesinvoice/customtags/tag/tagvalue", "datatype", "date");

        my $data = $invoice_xml->findnodes_as_string('root');
        my $response = $self->SUPER::request("salesinvoice.nv", "POST", $data, "?method=$postMethod");
        LogDebug("Response from API: $response->[1]");

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
