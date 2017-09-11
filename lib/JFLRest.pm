package JFLRest;

use Dancer ':syntax';
use Dancer::Plugin::ORMesque;
use Dancer::Plugin::REST;
use Dancer::Plugin::ValidateTiny;
use POSIX;

#-- set url prefix to .../rest/
prefix '/rest';

#-- set  before filter to automatically change the serializer when 
#-- a format is detected in the URI
prepare_serializer_for_format;

#-- declare resources the application will handle.
resource player => 
    get => \&on_get_player,
    create => \&on_create_player,
    update => \&on_update_player,    
    delete => \&on_delete_player;

# to update cancelled field:
# curl -X PUT -H "Content-Type: application/json" -d @test01.json http://localhost:3000/rest/player.json
# to update number field:
# curl -X PUT -H "Content-Type: application/json" -d @test02.json http://localhost:3000/rest/player.json
sub on_update_player  {
    debug "update...";
    my $params = params;
    my $data = validator($params, 'rest_player.pl');
    my $id = params->{'id'};
    
    if( $data->{valid} ) {
        db->player->update({
                               cancelled  => $data->{'result'}->{'cancelled'},
                               number     => $data->{'result'}->{'number'},
                           },
                           {
                               id => $id
                           }
        );
                         
        # Return the player object
        return status_ok ( db-player->read($id)->current );	
    }
    else {
        return status_bad_request($data->{'result'});
    }
}

true;
