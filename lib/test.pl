use strict;
use warnings;

use Data::Dumper;
use XML::XPath;



 # Create XML for post   
my $RootNode = XML::XPath::Node::Element->new('root',"");
my $customer_xml = XML::XPath->new(context => $RootNode);

$customer_xml->createNode("root/customer/customerbaseinformation/internalidentifier");
$customer_xml->setNodeText("root/customer/customerbaseinformation/internalidentifier", '123456');

my $text = $customer_xml->getNodeText("root/customer/customerbaseinformation/internalidentifier");
print $text;

my $data = $customer_xml->findnodes_as_string('root');
#my $data = ($customer_xml->findnodes('/'))[0]->toString();
print $data;

print Dumper($customer_xml);
