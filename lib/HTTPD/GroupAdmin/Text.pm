# $Id: Text.pm,v 1.13 1997/12/12 01:54:37 lstein Exp $
package HTTPD::GroupAdmin::Text;
use Carp ();
use strict;
use vars qw(@ISA $DLM $VERSION);
@ISA = qw(HTTPD::GroupAdmin);
$VERSION = (qw$Revision: 1.13 $)[1];
$DLM = ": ";

my %Default = (PATH => ".", 
	       DB => ".htgroup", 
	       FLAGS => "rwc",
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ } => $class;
    #load the DBM methods
    $self->load("HTTPD::GroupAdmin::DBM");
    $self->db($self->{DB}); 
    return $self;
}

sub _tie {
    my($self) = @_;
    my($fh,$db) = ($self->gensym(), $self->{DB});
    my($key,$val);
    printf STDERR "%s->_tie($db)\n", $self->class if $self->debug;

    $db =~ /^([^<>;|]+)$/ or Carp::croak("Bad file name '$db'"); $db = $1; #untaint	
    open($fh, $db) or return; #must be new

    while(<$fh>) {
	($key,$val) = $self->_parseline($fh, $_);
	next unless $key =~ /\S/;
	$self->{'_HASH'}{$key} = (exists $self->{'_HASH'}{$key} ?
				  join(" ", $self->{'_HASH'}{$key}, $val) :
				  $val);
    }
    close $fh;
}

sub _untie {
    my($self) = @_;
    return unless exists $self->{'_HASH'};
    $self->commit;
    delete $self->{'_HASH'};
}

DESTROY {
    $_[0]->_untie('_HASH');
    $_[0]->unlock;
}

sub commit {
    my($self) = @_;
    return if $self->readonly;
    my($fh,$db) = ($self->gensym(), $self->{DB});
    my($key,$val);

    $db =~ /^([^<>;|]+)$/ or return (0, "Bad file name '$db'"); $db = $1; #untaint
    open($fh, ">$db") or return (0, "open: '$db' $!");

    while(($key,$val) = each %{$self->{'_HASH'}}) {
	print $fh $self->_formatline($key,$val);
    }
    close $fh;
    1;
}

sub _parseline {
    my($self,$fh) = (shift,shift);
    local $_ = shift;
    chomp; s/^\s+//; s/\s+$//;
    my($key, $val) = split(/:\s*/, $_, 2);
    $val =~ s/\s* \s*/ /g;
    return ($key,$val);
}

sub _formatline {
    my($self,$key,$val) = @_;
    $val =~ s/(\w) /$1 /g;
    join($DLM, $key,$val) . "\n";
}

sub add {
    my $self = shift;
    return(0, $self->db . " is read-only!") if $self->readonly;
    $self->HTTPD::GroupAdmin::DBM::add(@_);
}

package HTTPD::GroupAdmin::Text::_generic;
use vars qw(@ISA);
@ISA = qw(HTTPD::GroupAdmin::Text
	  HTTPD::GroupAdmin::DBM);

1;

__END__
