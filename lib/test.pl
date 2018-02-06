use strict;
use warnings;

use Data::Dumper;
use XML::XPath;



#  Create XML for post   
my $RootNode = XML::XPath::Node::Element->new('root',"");
my $invoice_xml = XML::XPath->new(context => $RootNode);


  
# INVOICE LINE 1
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", 'netvisorid');
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier", "type", "netvisor");
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname", 'name');
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", 'price');
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice", "type", "net");

_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "0");
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage", "vatcode", "KOMY");
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity", "1");
	
# SET INVOICE LINE 2
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier[last()]", 'Netvisor_TShirtDiscountProductID');
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productidentifier[last()]", "type", "netvisor");
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productname[last()]", 'name');
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice[last()]", 'price');
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productunitprice[last()]", "type", "net");
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage[last()]", "0");
_xmlSetAttribute($invoice_xml, 	"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/productvatpercentage[last()]", "vatcode", "KOMY");
_xmlset($invoice_xml, 			"/salesinvoice/invoicelines/invoiceline/salesinvoiceproductline/salesinvoiceproductlinequantity[last()]", "1");




my $data = $invoice_xml->findnodes_as_string('/');
print $data . "\n";    


sub _xmlset {
    my ($Tree, $xpath, $value) = @_;

    if (!$Tree->exists($xpath)) {
        $Tree->createNode($xpath);
    
        if((defined $value) and ($value ne '')) {
        $Tree->setNodeText($xpath, $value);
        }
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