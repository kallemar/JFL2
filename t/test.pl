use strict;
use warnings;

use Data::Dumper;
use XML::XPath;



#  Create XML for post   
my $RootNode = XML::XPath::Node::Element->new('root',"");
my $invoice_xml = XML::XPath->new(context => $RootNode);


  
# INVOICE LINE 1
_xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline");

_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", 'netvisorid');
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "netvisor");
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname", 'name');
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", 'price');
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");

#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "0");
#_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "vatcode", "KOMY");
#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity", "1");
	
# SET INVOICE LINE 2
_xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline");
_xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline");
_xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier");
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "netvisor");
$invoice_xml->setNodeText("//invoiceline[last()]/salesinvoiceproductline/productidentifier", "333");

_xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname");
$invoice_xml->setNodeText("//invoiceline[last()]/salesinvoiceproductline/productname", "444");

_xmladd($invoice_xml, "/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice");
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");
$invoice_xml->setNodeText("//invoiceline[last()]/salesinvoiceproductline/productunitprice", "555");


#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", 'Netvisor_TShirtDiscountProductID');
#_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "netvisor");
#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname", 'name');
#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", 'price');
#_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");
#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "0");
#_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "vatcode", "KOMY");
#_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity", "1");


my $data = $invoice_xml->findnodes_as_string('/');
print $data . "\n";    

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