package Accession;
our $AUTOLOAD;

sub new {
    my $self = bless {}, shift;
    if ( @_ ) {
        my %args = @_;
        for my $key ( keys %args ) {
            $self->$key( $args{$key} );
        }
    }
    return $self;
}

sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    my $method = $AUTOLOAD;
    $method =~ s/.+://;
    if ( $method !~ /^[A-Z]+/ ) {
        if ( $arg ) {
            $self->{$method} = $arg;
        }
        return $self->{$method};
    }
}


1;