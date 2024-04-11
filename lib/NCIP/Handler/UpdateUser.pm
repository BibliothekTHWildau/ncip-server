package NCIP::Handler::UpdateUser;

=head1

  NCIP::Handler::UpdateUser

=head1 SYNOPSIS

    Not to be called directly, NCIP::Handler will pick the appropriate Handler 
    object, given a message type

=head1 FUNCTIONS

=cut

use Modern::Perl;
use Try::Tiny;

use NCIP::Handler;
use NCIP::User;

our @ISA = qw(NCIP::Handler);

sub handle {
    my $self   = shift;
    my $xmldoc = shift;

    my $config = $self->{config}->{koha};

    #my $ns = $self->{ncip_version} == 1 ? q{} : q{ns:};
    # as our vufind does not use namespace
    my $ns = $self->{ncip_version} == 1 ? q{} : q{};

    # todo remove log
    my $log = Log::Log4perl->get_logger("NCIP");

    if ($xmldoc) {

        # Given our xml document, lets find our userid
        my ($user_id) = $xmldoc->getElementsByTagNameNS( $self->namespace(),
            'UserIdentifierValue' );

        my $xpc  = $self->xpc();
        my $root = $xmldoc->documentElement();

        my $pin;
        my $userid =
          $xpc->findnodes( '//' . $ns . 'UserIdentifierValue', $root );

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
                elsif ( $class->[0]->textContent eq 'Password' ) {
                    $pin = $value->[0]->textContent;
                }

            }

        }

        if ( not $userid ) {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'UpdateUserResponse',
                    problems     => [
                        {
                            problem_type    => 'User Authentication Failed',
                            problem_detail  => 'UserId not set',
                            problem_element => 'UserId',
                            problem_value   => $userid,
                        }
                    ]
                }
            );
        }

        $log->debug("userid found $userid");

        # We may get a password, username combo instead of userid
        # Need to deal with that also

        my $user = NCIP::User->new( { userid => $userid, ils => $self->ils } );
        $user->initialise($config);

        if ( not $pin ) {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'UpdateUserResponse',
                    problems     => [
                        {
                            problem_type    => 'User Authentication Failed',
                            problem_detail  => 'Password not set',
                            problem_element => 'Password',
                            problem_value   => $pin,
                        }
                    ]
                }
            );
        }

        $log->debug("pin found");

        # pin is given check if user is valid
        unless ( $user->is_valid() ) {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'UpdateUserResponse',
                    problems     => [
                        {
                            problem_type   => 'User Authentication Failed',
                            problem_detail =>
                              'Barcode Id or Password are invalid',
                            problem_element => 'Password',
                            problem_value   => $pin,
                        }
                    ]
                }
            );
        }

        $log->debug("user valid");

        # valid data, authenticate
        my $authenticated = $user->authenticate( { pin => $pin } );

        unless ($authenticated) {    # User is valid, password is not
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'UpdateUserResponse',
                    problems     => [
                        {
                            problem_type   => 'User Authentication Failed',
                            problem_detail =>
                              'Barcode Id or Password are invalid',
                            problem_element => 'Password',
                            problem_value   => $pin,
                        }
                    ]
                }
            );
        }

        $log->debug("user authenticated");

        # find fields that shall be updated

        my @update_fields = $xpc->findnodes(
            '//' . $ns . 'AddUserFields/UserAddressInformation/Ext', $root );

        my @updates;

        foreach my $node (@update_fields) {
            my $class =
              $xpc->findnodes( './' . $ns . 'UnstructuredAddressType/Value',
                $node );
            $class ||=
              $xpc->findnodes( './' . $ns . 'UnstructuredAddressType', $node );

            my $value =
              $xpc->findnodes( './' . $ns . 'UnstructuredAddressData/Value',
                $node );
            $value ||=
              $xpc->findnodes( './' . $ns . 'UnstructuredAddressData', $node );

            if ( $class->[0]->textContent eq 'PIN' ) {
                push @updates,
                  {
                    'type' => 'new_password',
                    value  => $value->[0]->textContent
                  };

                #$new_password = $value->[0]->textContent;
            }

        }

        # no changes requested
        if ( scalar @updates == 0 ) {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'UpdateUserResponse',
                    problems     => [
                        {
                            problem_type    => 'No Fields to update',
                            problem_detail  => 'No fields given in request',
                            problem_element => '',
                            problem_value   => '',
                        }
                    ]
                }
            );
        }

        my @problems;

        #use Data::Dumper;
        foreach my $update (@updates) {

            if ( $update->{type} eq "new_password" ) {
                $log->debug('Password change requested');

                my $result = $user->set_password( $update->{value}, $config );

       #my $data = $self->ils->set_user_password( $userid, $password, $config );

                if ( $result->{success} ) {
                    $log->debug("success");
                }
                else {
                    push @problems, $result->{problems};
                }

            }

        }

        if ( scalar @problems > 0 ) {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'UpdateUserResponse',
                    problems     => @problems
                }
            );
        }

        return $self->render_output(
            'response.tt',
            {
                message_type => 'UpdateUserResponse',
                user_id      => $userid,

            }
        );

    }
}

1;
