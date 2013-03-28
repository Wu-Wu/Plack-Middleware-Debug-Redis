package Plack::Middleware::Debug::Redis::Info;

# ABSTRACT: Redis info debug panel

use strict;
use warnings;
use feature ':5.10';
use parent qw(Plack::Middleware::Debug::Base Plack::Middleware::Debug::Redis);

# VERSION
# AUTHORITY

sub prepare_app {
    my ($self) = @_;

    $self->redis_connect;
}

sub run {
    my ($self, $env, $panel) = @_;

    $panel->title('Redis::Info');
    $panel->nav_title($panel->title);

    my $info = $self->redis->info;

    # tweak db keys
    foreach my $db (grep { /^db\d{1,2}/ } keys %$info) {
        my $flatten = $self->flatten_db($db, $info->{$db});
        my @keys_flatten = keys %$flatten;
        @$info{@keys_flatten} = @$flatten{@keys_flatten};
        delete $info->{$db};
    }

    $panel->nav_subtitle('Version: ' . $info->{redis_version});

    return sub {
        $panel->content($self->render_hash($info));
    };
}

sub flatten_db {
    my ($self, $database, $value) = @_;

    my %flatten = ();

    %flatten = map {
        my @ary = split /=/;
        $database . '_' . $ary[0] => $ary[1];
    } split /,/, $value;

    \%flatten;
}

1; # End of Plack::Middleware::Debug::Redis::Info

__END__

=pod

=head1 SYNOPSIS

    # inside your psgi app
    enable 'Debug',
        panels => [
            [ 'Redis::Info', server => 'redis.example.com:6379' ],
        ];

=head1 DESCRIPTION

Plack::Middleware::Debug::Redis::Info extends Plack::Middleware::Debug by adding redis server info debug panel.
Panel displays data which available through INFO command issued in redis-cli. Before displaying info some tweaks
were processed. Normally INFO command shows total and expires keys in one line such as

    db0 => 'keys=167,expires=145',
    db1 => 'keys=75,expires=0',

This module turn in to

    db0_expires => '145',
    db0_keys    => '167',
    db1_expires => '0',
    db1_keys    => '75',

=head1 METHODS

=head2 prepare_app

See L<Plack::Middleware::Debug>

=head2 run

See L<Plack::Middleware::Debug>

=head2 redis

=head2 flatten_db

=head2 server

Hostname and port of redis server instance. Default value is 'localhost:6379'.

=head2 password

Password to authenticate on redis server instance in case of enabled redis' option B<requirepass>.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Debug-Redis/issues>

=head1 SEE ALSO

L<Plack::Middleware::Debug>

L<Redis>

=cut
