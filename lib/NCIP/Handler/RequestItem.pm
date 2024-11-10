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

    # as our vufind does not use namespace
    my $ns = q{};

    if ($xmldoc) {
        # todo delete
        #use Data::Dumper;
        #my $log = Log::Log4perl->get_logger("NCIP");

        my ($userid,$pin) = $self->get_userid( $xmldoc );

        my $xpc = $self->xpc();
        my $root = $xmldoc->documentElement();

        # item
        my $itemid   = $xpc->findnodes( '//*[local-name()="ItemIdentifierValue"]', $root );
        $itemid = $itemid->[0]->textContent() if $itemid;

        my $biblionumber = $xpc->findnodes( '//*[local-name()="BibliographicRecordIdentifier"]', $root );
        $biblionumber = $biblionumber->[0]->textContent() if $biblionumber;;

        my $request_scope = $xpc->findnodes( '//*[local-name()="RequestScopeType"]', $root );
        $request_scope = $request_scope->[0]->textContent() if $request_scope;

        if ($request_scope eq 'BibliographicId') {
          # request is for a biblio
          $biblionumber = $itemid if not $biblionumber;
          $itemid = undef;
        }

        my $branchcode;
        my $type = 'SYSNUMBER';

        my ( $from, $to ) = $self->get_agencies($xmldoc);

        $branchcode = $to->[0]->textContent() if $to;

        my $config = $self->{config}->{koha};
        my $ignore_item_requests = $config->{ignore_item_requests};

        my $data;
        if ($ignore_item_requests) {
            $data = {
                success    => 1,
                request_id => 0,
            };
        }
        else {
            #todo remove
            #my $log = Log::Log4perl->get_logger("NCIP");
            #$log->info( Dumper($userid,$itemid,$biblionumber,$type,$branchcode) );
            $data = $self->ils->request( $userid, $itemid, $biblionumber, $type, $branchcode, $config );
        }

        if ( $data->{success} ) {
            my $elements = $self->get_user_elements($xmldoc);
            return $self->render_output(
                'response.tt',
                {
                    message_type => 'RequestItemResponse',
                    from_agency  => $to,
                    to_agency    => $from,
                    barcode      => $itemid,
                    request_id   => $data->{request_id},
                    elements     => $elements,
                }
            );
        }
        else {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'RequestItemResponse',
                    problems     => $data->{problems},
                    from_agency  => $to,
                    to_agency    => $from,
                }

            );
        }
    }
}

1;
