# --
# Kernel/System/Support/OTRS.pm - all required otrs informations
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: OTRS.pm,v 1.13 2008-05-01 16:52:02 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.
# --

package Kernel::System::Support::OTRS;

use strict;
use warnings;

use Kernel::System::Support;
use Kernel::System::Ticket;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.13 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for (qw(ConfigObject LogObject MainObject DBObject)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    $Self->{SupportObject} = Kernel::System::Support->new(%Param);
    $Self->{TicketObject}  = Kernel::System::Ticket->new(%Param);

    return $Self;
}

sub SupportConfigArrayGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw()) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    # create config array
    my $ConfigArray = [

    ];

    # return config array
    return $ConfigArray;
}

sub SupportInfoGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ModuleInputHash} ) {
        $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
        return;
    }
    if ( ref( $Param{ModuleInputHash} ) ne 'HASH' ) {
        $Self->{LogObject}
            ->Log( Priority => 'error', Message => "ModuleInputHash must be a hash reference!" );
        return;
    }

    # add new function name here
    my @ModuleList = (
        '_OTRSLogGet', '_OTRSKernelGet',
        '_OTRSCheckSumGet', '_OTRSCheckModulesGet',
        '_OpenTicketCheck', '_TicketIndexModuleCheck',
        '_FQDNConfigCheck', '_SystemIDConfigCheck', '_LogCheck',
    );

    my @DataArray;

    FUNCTIONNAME:
    for my $FunctionName (@ModuleList) {

        # run function and get check data
        my $Check = $Self->$FunctionName( Type => $Param{ModuleInputHash}->{Type} || '', );

        next FUNCTIONNAME if !$Check;

        # attach check data if valid
        push @DataArray, $Check;
    }

    return \@DataArray;
}

sub AdminChecksGet {
    my ( $Self, %Param ) = @_;

    # add new function name here
    my @ModuleList = (
        '_OpenTicketCheck', '_TicketIndexModuleCheck',
        '_FQDNConfigCheck', '_SystemIDConfigCheck', '_LogCheck',
    );

    my @DataArray;

    FUNCTIONNAME:
    for my $FunctionName (@ModuleList) {

        # run function and get check data
        my $Check = $Self->$FunctionName();

        next FUNCTIONNAME if !$Check;

        # attach check data if valid
        push @DataArray, $Check;
    }

    return \@DataArray;
}

sub _OTRSLogGet {
    my ( $Self, %Param ) = @_;

    my $ReturnHash = {};

    # check needed stuff
    for (qw()) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }
    my $LogString = $Self->{LogObject}->GetLog( Limit => 1000 );
    my $TmpLog;
    open( $TmpLog, '>', $Self->{ConfigObject}->Get('Home') . "/var/tmp/tmplog" );
    print $TmpLog $LogString;
    close($TmpLog);

    my $Filename = $Self->{SupportObject}->TarPackageWrite(
        FileName   => $Self->{ConfigObject}->Get('Home') . "/var/tmp/tmplog",
        OutputPath => $Self->{ConfigObject}->Get('Home') . "/var/tmp/support/",
        OutputName => 'otrs.log.tar',
    );

    # remove tmp file
    unlink $Self->{ConfigObject}->Get('Home') . "/var/tmp/tmplog";

    if ($Filename) {
        $ReturnHash = {
            Key         => 'OTRSLog',
            Name        => 'OTRSLog',
            Comment     => 'The OTRS Log',
            Description => $Filename,
            Check       => 'Package',
        };
    }
    return $ReturnHash;
}

sub _OTRSKernelGet {
    my ( $Self, %Param ) = @_;

    my $ReturnHash = {};

    # check needed stuff
    for (qw()) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    # get the directory name
    my $DirName = $Self->{ConfigObject}->Get('Home') . '/Kernel/';

    my $Filename = $Self->{SupportObject}->TarPackageWrite(
        DirName    => $DirName,
        OutputPath => $Self->{ConfigObject}->Get('Home') . "/var/tmp/support/",
        OutputName => 'kernel.tar',
    );

    if ($Filename) {
        $ReturnHash = {
            Key         => 'OTRSKernel',
            Name        => 'OTRSKernel',
            Comment     => 'The OTRS Kernel ',
            Description => $Filename,
            Check       => 'Package',
        };
    }
    return $ReturnHash;
}

sub _OTRSCheckSumGet {
    my ( $Self, %Param ) = @_;

    my $ReturnHash = {};

    # check needed stuff
    for (qw()) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    my $TmpSumString;
    my $TmpLog;
    open( $TmpSumString, "perl " . $Self->{ConfigObject}->Get('Home') . "/bin/CheckSum.pl |" );
    open( $TmpLog, '>', $Self->{ConfigObject}->Get('Home') . "/var/tmp/CheckSum.log" );

    while (<$TmpSumString>) {
        print $TmpLog $_;
    }
    close($TmpSumString);
    close($TmpLog);

    my $Filename = $Self->{SupportObject}->TarPackageWrite(
        FileName   => $Self->{ConfigObject}->Get('Home') . "/var/tmp/CheckSum.log",
        OutputPath => $Self->{ConfigObject}->Get('Home') . "/var/tmp/support/",
        OutputName => 'CheckSum.log.tar',
    );

    # remove tmp file
    unlink $Self->{ConfigObject}->Get('Home') . "/var/tmp/CheckSum.log";

    if ($Filename) {
        $ReturnHash = {
            Key         => 'OTRSCheckSum',
            Name        => 'OTRSCheckSum',
            Comment     => 'The OTRS CheckSum.',
            Description => $Filename,
            Check       => 'Package',
        };
    }
    return $ReturnHash;
}

sub _OTRSCheckModulesGet {
    my ( $Self, %Param ) = @_;

    my $ReturnHash = {};

    # check needed stuff
    for (qw()) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    my $TmpSumString;
    my $TmpLog;
    open( $TmpSumString,
        "perl " . $Self->{ConfigObject}->Get('Home') . "/bin/otrs.checkModules |" );
    open( $TmpLog, '>', $Self->{ConfigObject}->Get('Home') . "/var/tmp/CheckModules.log" );

    while (<$TmpSumString>) {
        print $TmpLog $_;
    }
    close($TmpSumString);
    close($TmpLog);

    my $Filename = $Self->{SupportObject}->TarPackageWrite(
        FileName   => $Self->{ConfigObject}->Get('Home') . "/var/tmp/CheckModules.log",
        OutputPath => $Self->{ConfigObject}->Get('Home') . "/var/tmp/support/",
        OutputName => 'CheckModules.log.tar',
    );

    # remove tmp file
    unlink $Self->{ConfigObject}->Get('Home') . '/var/tmp/CheckModules.log';

    if ($Filename) {
        $ReturnHash = {
            Key         => 'OTRSCheckSum',
            Name        => 'OTRSCheckSum',
            Comment     => 'The OTRS CheckSum.',
            Description => $Filename,
            Check       => 'Package',
        };
    }
    return $ReturnHash;
}

# check if error log entries are available
sub _LogCheck {
    my ( $Self, %Param ) = @_;

    my $Data = {};

    # Ticket::IndexModule check
    my $Check   = 'OK';
    my $Message = '';
    my $Error   = '';

    my @Lines = split( /\n/, $Self->{LogObject}->GetLog() );
    for (@Lines) {
        my @Row = split( /;;/, $_ );
        if ( $Row[3] ) {
            if ( $Row[1] =~ /error/i ) {
                $Check = 'Failed';
                if ($Message) {
                    $Message = 'You have more error log entries: ';
                }
                else {
                    $Message = 'There is one error log entry: ';
                }
                if ($Error) {
                    $Error .= ', ';
                }
                $Error .= $Row[3];
            }
        }
    }

    $Data = {
        Key         => 'LogCheck',
        Name        => 'LogCheck',
        Description => 'Check log for error log entries.',
        Comment     => $Message . $Error,
        Check       => $Check,
    };
    return $Data;
}

sub _TicketIndexModuleCheck {
    my ( $Self, %Param ) = @_;

    my $Data = {};

    # Ticket::IndexModule check
    my $Check   = 'Failed';
    my $Message = '';
    my $Module  = $Self->{ConfigObject}->Get('Ticket::IndexModule');
    $Self->{DBObject}->Prepare( SQL => 'SELECT count(*) from ticket' );
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        if ( $Row[0] > 80000 ) {
            if ( $Module =~ /RuntimeDB/ ) {
                $Check = 'Failed';
                $Message = "$Row[0] tickets in your system. You should use the StaticDB backend. See admin manual (Performance Tuning) for more information.";
            }
            else {
                $Check   = 'OK';
                $Message = "";
            }
        }
        elsif ( $Row[0] > 60000 ) {
            if ( $Module =~ /RuntimeDB/ ) {
                $Check = 'Critical';
                $Message = "$Row[0] tickets in your system. You should use the StaticDB backend. See admin manual (Performance Tuning) for more information.";
            }
            else {
                $Check   = 'OK';
                $Message = "";
            }
        }
        else {
            $Check   = 'OK';
            $Message = "You are using \"$Module\", that's fine for $Row[0] tickets in your system.";
        }
    }
    $Data = {
        Key         => 'Ticket::IndexModule',
        Name        => 'Ticket::IndexModule',
        Description => 'Check Ticket::IndexModule setting.',
        Comment     => $Message,
        Check       => $Check,
    };
    return $Data;
}

# OpenTicketCheck check
sub _OpenTicketCheck {
    my ( $Self, %Param ) = @_;

    my $Data = {};

    my $Check     = 'Failed';
    my $Message   = '';
    my @TicketIDs = $Self->{TicketObject}->TicketSearch(
        Result     => 'ARRAY',
        StateType  => 'Open',
        UserID     => 1,
        Permission => 'ro',
        Limit      => 89999,
    );
    if ( $#TicketIDs > 89990 ) {
        $Check = 'Failed';
        $Message = 'You should not have more then 8000 open tickets in your system. You currently have over 89999! In case you want to improve your performance, close not needed open tickets.';

    }
    elsif ( $#TicketIDs > 10000 ) {
        $Check = 'Failed';
        $Message = 'You should not have more then 8000 open tickets in your system. You currently have '
            . $#TicketIDs
            . '. In case you want to improve your performance, close not needed open tickets.';

    }
    elsif ( $#TicketIDs > 8000 ) {
        $Check = 'Critical';
        $Message = 'You should not have more then 8000 open tickets in your system. You currently have '
            . $#TicketIDs
            . '. In case you want to improve your performance, close not needed open tickets.';

    }
    else {
        $Check   = 'OK';
        $Message = 'You have ' . $#TicketIDs . ' open tickets in your system.';
    }
    $Data = {
        Key         => 'OpenTicketCheck',
        Name        => 'OpenTicketCheck',
        Description => 'Check open tickets in your system.',
        Comment     => $Message,
        Check       => $Check,
    };
    return $Data;
}

# Check if the configured FQDN is valid.
sub _FQDNConfigCheck {
    my ( $Self, %Param ) = @_;
    my $Data = {
        Key         => 'FQDNConfigCheck',
        Name        => 'FQDNConfigCheck',
        Description => 'Check if the configured fully qualified host name is valid.',
        Check       => 'Failed',
        Comment     => '',
    };

    # Get the configured FQDN
    my $FQDN = $Self->{ConfigObject}->Get('FQDN');

    # Do we have set our FQDN?
    if ( $FQDN eq 'yourhost.example.com' ) {
        $Data->{Check}   = 'Failed';
        $Data->{Comment} = "Please configure your FQDN (it's currently default setting '$FQDN').";
    }

    # FQDN syntax check.
    elsif ( $FQDN =~ /\.\.|\s|[^a-zA-Z0-9-.]/g ) {
        $Data->{Check}   = 'Failed';
        $Data->{Comment} = "Invalid FQDN '$FQDN'.";
    }

    # Nothing to complain. :-(
    else {
        $Data->{Check}   = 'OK';
        $Data->{Comment} = "FQDN '$FQDN' looks good.";
    }
    return $Data;
}

# Check if the SystemID contains only digits.
sub _SystemIDConfigCheck {
    my ( $Self, %Param ) = @_;
    my $Data = {
        Key         => 'SystemIDConfigCheck',
        Name        => 'SystemIDConfigCheck',
        Description => 'Check if the configured SystemID contains only digits.',
        Check       => 'Failed',
        Comment     => '',
    };

    # Get the configured SystemID
    my $SystemID = $Self->{ConfigObject}->Get('SystemID');

    # Does the SystemID contain non-digits?
    if ( $SystemID =~ /^\d+$/ ) {
        $Data->{Check}   = 'OK';
    }
    else {
        $Data->{Check}   = 'Failed';
        $Data->{Comment} = "The SystemID '$SystemID' must consist of digits exclusively.";
    }
    return $Data;
}
1;
