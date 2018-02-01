use strict;
use warnings;

use Data::Dumper;
use XML::XPath;



 # Create XML for post   
my $RootNode = XML::XPath::Node::Element->new('root',"");
my $customer_xml = XML::XPath->new(context => $RootNode);

$customer_xml->createNode("/customer/customerbaseinformation/internalidentifier");
$customer_xml->setNodeText("/customer/customerbaseinformation/internalidentifier", '123456');
my $text = $customer_xml->getNodeText("/customer/customerbaseinformation/internalidentifier");
print $text . "\n";

my $data = $customer_xml->findnodes_as_string('/');
print $data . "\n";

#if(!$Tree->exists($xpath)) {
#        $Tree->createNode($xpath);
#}

 my $AttributeNode = XML::XPath::Node::Attribute->new("TYPE", "KUKKUU", '');

#my $nodeset = $customer_xml->find("/customer/customerbaseinformation/internalidentifier");
#if (!$nodeset->isa('XML::XPath::NodeSet')) {
#    foreach my $Node ($nodeset->get_nodelist) {
#        print "HEP\n";
#        $Node->appendAttribute($AttributeNode);
#    }
#}
        
my $Node = $customer_xml->find("/customer/customerbaseinformation/internalidentifier")->get_node(1);
#my $AttributeNode = XML::XPath::Node::Attribute->new($AttributeKey, $AttributeValue, '');
$Node->appendAttribute($AttributeNode);

