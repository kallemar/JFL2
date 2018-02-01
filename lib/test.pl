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


my $AttributeNode = XML::XPath::Node::Attribute->new("TYPE", "KUKKUU", '');
my $Node = $customer_xml->find("/customer/customerbaseinformation/internalidentifier")->get_node(1);
$Node->appendAttribute($AttributeNode);


my $data = $customer_xml->findnodes_as_string('/');
print $data . "\n";    


