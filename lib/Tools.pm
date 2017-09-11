package Tools;
use DateTime::Format::Strptime;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(to_epoch);

sub to_epoch {
    my $dt = defined($_[0]) ? $_[0] : return undef;
    my $strp = DateTime::Format::Strptime->new( pattern   => '%d.%m.%Y',
                                                time_zone => 'UTC',
                                                on_error  => 'undef',
                                              );
   if( defined($strp->parse_datetime($_[0])) ) {
       return $strp->parse_datetime($_[0])->truncate(to => 'day')->epoch;
   }
   return undef;
}

true;
