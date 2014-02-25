package NCIP::Handler::RequestItem;

=head1

  NCIP::Handler::RequestItem

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
    if ($xmldoc) {
        my $root = $xmldoc->documentElement();
        my $xpc  = XML::LibXML::XPathContext->new;
        $xpc->registerNs( 'ns', $self->namespace() );

        my $userid =
          $xpc->findnodes( 'ns:RequestItem/UniqueUserId/UserIdentifierValue',
            $root );
        my $itemid =
          $xpc->findnodes( 'ns:RequestItem/UniqueItemId/ItemIdentifierValue',
            $root );

        # checkout the item
        my ( $error, $messages ) = $self->ils->request( $userid, $itemid );
        my $vars;
        my $output;
        my $vars->{'barcode'} = $itemid;
        $vars->{'messagetype'} = 'RequestItemResponse';
        if ($error) {
            $vars->{'processingerror'}        = 1;
            $vars->{'processingerrortype'}    = $messages;
            $vars->{'processingerrorelement'} = 'UniqueItemIdentifier';
            $output = $self->render_output( 'problem.tt', $vars );
        }
        else {
            my $elements = $self->get_user_elements($xmldoc);
            $vars->{'elements'} = $elements;

            $output = $self->render_output( 'response.tt', $vars );
        }
        return $output;
    }
}

1;
