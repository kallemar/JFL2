package Dancer::Plugin::Auth::Extensible::Provider::JFLAuth;
use base 'Dancer::Plugin::Auth::Extensible::Provider::Database';

use Dancer ':syntax';
use Dancer::Plugin::Database;


# Return details about the user.  The user's row in the users table will be
# fetched and all columns returned as a hashref.
sub get_user_details {
    my ($self, $username) = @_;
    return unless defined $username;

    my $settings = $self->realm_settings;

    # Get our database handle and find out the table and column names:
    my $database = database($settings->{db_connection_name})
        or die "No database connection";

    my $users_table     = $settings->{users_table}     || 'users';
    my $username_column = $settings->{users_username_column} || 'username';
    my $password_column = $settings->{users_password_column} || 'password';

    # Only one entry in users table, season doesn't matter
    if( $database->quick_count($users_table, { $username_column => $username }) == 1 ) {
        # Look up the user, 
        my $user = $database->quick_select(
            $users_table, { $username_column => $username }
        );
#        debug("---USER---USER-- ", $user);
     
        if( defined $user) {
            return $user;
        } 
        else {
            debug("No such user $username");
            return;
        }
    }
    # Multiple entries in users table. Must be coach or contact and in active season.
    else {
        # get active season
        my $season = $database->quick_select(
            'season', { isactive => 1}
        );
        my $seasonid = $season->{'id'};
        
        # get users
        my @users = $database->quick_select(
            $users_table, { $username_column => $username }
        );      
        
        foreach my $user (@users) {
         
         #is contact
         if( defined $user->{contactid} ) {
             #debug('CONTACT: ', $user->{contactid}, $seasonid);
             
             my $contact = $database->quick_select(
                 'contact', { id => $user->{contactid}, seasonid => $seasonid }
             );
             
             if( defined $contact ) {
                 return $user;    
             }
         }
         
         #is coach
         if( defined $user->{coachid} ) {
             #debug('COACH: ', $user->{coachid}, $seasonid);
             
             my $coach = $database->quick_select(
                 'coach', { id => $user->{coachid}, seasonid => $seasonid }
             );
             
             if( defined $coach ) {
                 return $user;    
             }            
         }
        }
		return;
	}
}

1;
