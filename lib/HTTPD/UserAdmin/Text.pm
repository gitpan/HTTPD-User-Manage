# $Id: Text.pm,v 1.1.1.1 2001/02/20 03:19:07 lstein Exp $
package HTTPD::UserAdmin::Text;
use HTTPD::UserAdmin ();
use Carp ();
use strict;
use vars qw(@ISA $DLM $VERSION);
@ISA = qw(HTTPD::UserAdmin::DBM HTTPD::UserAdmin);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];
$DLM = ":";

my %Default = (PATH => ".", 
	       DB => ".htpasswd", 
	       FLAGS => "rwc",
	       );

sub new {
    my($class) = shift;
    my $self = bless { %Default, @_ }, $class;

    #load the DBM methods
    $self->load("HTTPD::UserAdmin::DBM");

    $self->db($self->{DB}); 
    return $self;
}

#do this so we can borrow from the DBM class

sub _tie {
    my($self) = @_;
    my($fh,$db) = ($self->gensym(), $self->{DB});
    printf STDERR "%s->_tie($db)\n", $self->class if $self->debug;

    $db =~ /^([^<>;|]+)$/ or Carp::croak("Bad file name '$db'"); $db = $1; #untaint
    open($fh, $db) or return;
    my($key,$val);
    
    while(<$fh>) { #slurp! need a better method here.
	($key,$val) = $self->_parseline($fh, $_);
	$self->{'_HASH'}{$key} = $val; 
    }
    CORE::close $fh;
}

sub _untie {
    my($self) = @_;
    return unless exists $self->{'_HASH'};
    $self->commit;
    delete $self->{'_HASH'};
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
    CORE::close $fh;
    1;
}

sub _parseline {
    my($self,$fh,$line) = @_;
    chomp $line;
    my($key, $val) = split($DLM, $line, 2);
    return ($key,$val);
}

sub _formatline {
    my($self,$key,$val) = @_;
    join($DLM, $key,$val) . "\n";
}

package HTTPD::UserAdmin::Text::_generic;
use vars qw(@ISA);
@ISA = qw(HTTPD::UserAdmin::Text
	  HTTPD::UserAdmin::DBM);

1;

__END__





