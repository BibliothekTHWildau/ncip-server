package NCIP::Handler::RenewItem;

=head1

  NCIP::Handler::RenewItem

=head1 SYNOPSIS

    Not to be called directly, NCIP::Handler will pick the appropriate Handler 
    object, given a message type

=head1 FUNCTIONS

=cut

use Modern::Perl;

use NCIP::Handler;

our @ISA = qw(NCIP::Handler);

sub handle {
    my $self   = shift;
    my $xmldoc = shift;
    my $config = $self->{config}->{koha};

    if ($xmldoc) {

        my $root = $xmldoc->documentElement();
        my $xpc  = $self->xpc();
        
        my ($userid,$pin) = $self->get_userid( $xmldoc );

        #todo remove
        #use Data::Dumper;
        #my $log = Log::Log4perl->get_logger("NCIP");

        my $itemid   = $xpc->findnodes( '//*[local-name()="ItemIdentifierValue"]', $root );
        $itemid = $itemid->[0]->textContent() if $itemid;

        my ( $from, $to ) = $self->get_agencies($xmldoc);

        my $data = $self->ils->renew( $itemid, $userid, $config );

        if ( $data->{success} ) {
            my @elements = $root->findnodes('RenewItem/ItemElementType/Value');
            return $self->render_output(
                'response.tt',
                {
                    message_type => 'RenewItemResponse',
                    from_agency  => $to,
                    to_agency    => $from,
                    barcode      => $itemid,
                    userid       => $userid,
                    elements     => \@elements,
                    data         => $data,
                }
            );
        }
        else {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'RenewItemResponse',
                    problems     => $data->{problems},
                    from_agency  => $to,
                    to_agency    => $from,
                }
            );
        }
    }
}

1;
