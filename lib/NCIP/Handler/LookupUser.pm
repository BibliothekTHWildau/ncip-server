package NCIP::Handler::LookupUser;

=head1

  NCIP::Handler::LookupUser

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

    my $config = $self->{config}->{koha};
    #my $ns = $self->{ncip_version} == 1 ? q{} : q{ns:};
    # as our vufind does not use namespace
    my $ns = $self->{ncip_version} == 1 ? q{} : q{};

    if ($xmldoc) {

        # Given our xml document, lets find our userid
        # We may get a password, username combo instead of userid
        # Need to deal with that also
        my ($userid,$pin) = $self->get_userid( $xmldoc );

        my $user = NCIP::User->new( { userid => $userid, ils => $self->ils } );
        $user->initialise($config);

        if ($pin) {
            if ( $user->is_valid() ) {
                my $authenticated = $user->authenticate( { pin => $pin } );

                unless ($authenticated) {    # User is valid, password is not
                    return $self->render_output(
                        'problem.tt',
                        {
                            message_type => 'LookupUserResponse',
                            problems     => [
                                {
                                    problem_type =>
                                      'User Authentication Failed',
                                    problem_detail =>
                                      'Barcode Id or Password are invalid',
                                    problem_element => 'Password',
                                    problem_value   => $pin,
                                }
                            ]
                        }
                    );
                }
            }
            else {    # User is invalid
                return $self->render_output(
                    'problem.tt',
                    {
                        message_type => 'LookupUserResponse',
                        problems     => [
                            {
                                problem_type => 'User Authentication Failed',
                                problem_detail =>
                                  'Barcode Id or Password are invalid',
                                problem_element => 'Barcode Id',
                                problem_value   => $userid,
                            }
                        ]
                    }
                );
            }
        } 
        else {
          # if no pin is set
          return $self->render_output(
                        'problem.tt',
                        {
                            message_type => 'LookupUserResponse',
                            problems     => [
                                {
                                    problem_type =>
                                      'User Authentication Failed',
                                    problem_detail =>
                                      'Password not set',
                                    problem_element => 'Password',
                                    problem_value   => $pin,
                                }
                            ]
                        }
                    );
        }

        my $vars;

        #  this bit should be at a lower level
        my ( $from, $to ) = $self->get_agencies($xmldoc);

        # we switch these for the templates
        # because we are responding, to becomes from, from becomes to

        # if we have blank user, we need to return that
        # and can skip looking for elementtypes
        if ( $user->is_valid() ) {
            my $elements = $self->get_user_elements($xmldoc);

            # todo remove log
            #my $log = Log::Log4perl->get_logger("NCIP"); 

            # checked out items and holds / reserves
            my $loaned_items    = $user->items($config,'loaned') if ($self->get_desired_fields($xmldoc,'LoanedItemsDesired'));
            my $requested_items = $user->items($config,'requested') if ($self->get_desired_fields($xmldoc,'RequestedItemsDesired'));
            
            #todo
            my $fiscal_account = $user->fiscal_account($config) if ($self->get_desired_fields($xmldoc,'UserFiscalAccountDesired'));
            
            return $self->render_output(
                'response.tt',
                {
                    message_type => 'LookupUserResponse',
                    from_agency  => $to,
                    to_agency    => $from,
                    elements     => $elements,
                    loaned_items => $loaned_items,
                    requested_items => $requested_items,
                    fiscal_account => $fiscal_account,
                    user         => $user,
                    user_id      => $userid,
                    config       => $config,
                }
            );
        }
        else {
            return $self->render_output(
                'problem.tt',
                {
                    message_type => 'LookupUserResponse',
                    problems     => [
                        {
                            problem_type    => 'Unkown User',
                            problem_detail  => 'User is not known',
                            problem_element => 'UserId',
                            problem_value   => $userid,
                        }
                    ],
                    from_agency  => $to,
                    to_agency    => $from,
                }
            );
        }
    }
}

1;
