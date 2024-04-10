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

    # as our vufind does not use namespace
    my $ns = q{};
    #todo remove
    my $log = Log::Log4perl->get_logger("NCIP");

    if ($xmldoc) {
        my $root = $xmldoc->documentElement();
        my $xpc  = $self->xpc();
        my $userid   = $xpc->findnodes( '//'.$ns.'UserIdentifierValue', $root );

        unless ($userid) {          

            # We may get a password, username combo instead of userid
            # Need to deal with that also
            my $root = $xmldoc->documentElement();
            my @authtypes = $xpc->findnodes( '//' . $ns . 'AuthenticationInput', $root );

            foreach my $node (@authtypes) {
                
                my $class = $xpc->findnodes( './' . $ns . 'AuthenticationInputType/Value', $node );
                $class ||= $xpc->findnodes( './' . $ns . 'AuthenticationInputType', $node );

                my $value = $xpc->findnodes( './' . $ns . 'AuthenticationInputData/Value', $node );
                $value ||= $xpc->findnodes( './' . $ns . 'AuthenticationInputData', $node );

                if ( $class->[0]->textContent eq 'UserId' ) {
                    $userid = $value->[0]->textContent;
                    last;
                }
            }
            
        }       
        

        my $itemid   = $xpc->findnodes( '//'.$ns.'ItemIdentifierValue', $root );

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
