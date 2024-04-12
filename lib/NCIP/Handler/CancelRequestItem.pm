package NCIP::Handler::CancelRequestItem;

=head1

  NCIP::Handler::CancelRequestItem

=head1 SYNOPSIS

    Not to be called directly, NCIP::Handler will pick the appropriate Handler 
    object, given a message type

=head1 FUNCTIONS

=cut

use Modern::Perl;

use NCIP::Handler;
use NCIP::User;

our @ISA = qw(NCIP::Handler);

sub handle {
    my $self   = shift;
    my $xmldoc = shift;

    #my $config = $self->{config}->{koha};

    my $ns = $self->{ncip_version} == 1 ? q{} : q{};

    if ($xmldoc) {
        my $root = $xmldoc->documentElement();
        my $xpc  = $self->xpc();
        my $userid =
          $xpc->findnodes( '//' . $ns . 'UserIdentifierValue', $root );
        my $requestid =
          $xpc->findnodes( '//' . $ns . 'RequestIdentifierValue', $root )->[0]
          ->textContent;
        my $requesttype =
          $xpc->findnodes( '//' . $ns . 'RequestType', $root )->[0]
          ->textContent;

        unless ($requestid) {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'CancelRequestItemResponse',
                    problems     => [
                        {
                            problem_type    => 'Unknown Request',
                            problem_detail  => 'Request is not known.',
                            problem_element => 'RequestIdentifierValue',
                            problem_value   => $requestid,
                        }
                    ]
                }
            );
        }

        unless ($userid) {

            # We may get a password, username combo instead of userid
            # Need to deal with that also
            my $root = $xmldoc->documentElement();
            my @authtypes =
              $xpc->findnodes( '//' . $ns . 'AuthenticationInput', $root );

            foreach my $node (@authtypes) {

                my $class =
                  $xpc->findnodes( './' . $ns . 'AuthenticationInputType/Value',
                    $node );
                $class ||=
                  $xpc->findnodes( './' . $ns . 'AuthenticationInputType',
                    $node );

                my $value =
                  $xpc->findnodes( './' . $ns . 'AuthenticationInputData/Value',
                    $node );
                $value ||=
                  $xpc->findnodes( './' . $ns . 'AuthenticationInputData',
                    $node );

                if ( $class->[0]->textContent eq 'UserId' ) {
                    $userid = $value->[0]->textContent;
                }
            }
        }

        my $data =
          $self->ils->cancelrequest( $userid, $requestid, $requesttype );

        if ( $data->{success} ) {
            return $self->render_output(
                'response.tt',
                {
                    message_type => 'CancelRequestItemResponse',
                    request_id   => $requestid,
                }
            );
        }
        else {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'CancelRequestItemResponse',
                    problems     => [
                        {
                            problem_type    => 'No hold found',
                            problem_detail  => 'Request is not known.',
                            problem_element => 'RequestIdentifierValue',
                            problem_value   => $requestid,
                        }
                    ]
                }
            );
        }
    }
}

1;
