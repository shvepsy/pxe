#!/bin/perl

use WWW::Mechanize;
use JSON;
use JSON::Parse;
#use POSIX qw(strftime);
#my $now = localtime;

my $m = WWW::Mechanize->new( agent => 'PostBot/0.1');

my $servername = shift;
my $user = shift;
unless ($servername && $user ) { print ("Usage: <Server> <LdapUsername>\n") ; exit } ;

print "Ldap password?\n" ;

system("stty -echo");
my $pass = <STDIN>;
chomp($pass);
system("stty echo");


my $comm = "Free!!!\nTesting, desirable to sell the last" ;

$urllogin = 'https://admin.ddos-guard.net/site/login'; 
$urlindex = 'https://admin.ddos-guard.net/data-center/index-server' ;

$m->get($urllogin);

my ($csr_input) = $m->find_all_inputs(name => '_csrf');
my $token = $csr_input->value();

$m->post($urllogin, Content => 
{ 
	_csrf => $token, 
	'AdminLoginForm[username]' => $user, 
	'AdminLoginForm[password]' => $pass, 
	'AdminLoginForm[rememberMe]' => 0 
} ) ; 

$m->get($urlindex);


my $key = $m->content ;
my @k = split /\<a\s/, $key ;
my @sstring = grep (/$servername\</, @k) ;
my ($sid) = $sstring[0] =~ /\?id\=(\d+)/ ;  # please save old ips
unless ($sid) { print "Can't find servername" ; exit ; } else {print "Server: $servername  \tid: $sid\n"; } ;

#use Data::Dumper; print Dumper($sid); exit;

$urlupdate = "https://admin.ddos-guard.net/data-center/update-server?id=$sid"; 

$m->get($urlupdate);

my (@Data) = $m->find_all_inputs( name_regex => qr/(_csrf|DataCenterServer)/ );

$i = 0;
foreach $_ ($csrf, $sw_id, $name, $type_id, $status, $expr, $port, $vlan, $p_speed, $hw, $comment, $ip_i, $pass_i) {
	$_ = $Data[$i]->value() ;
	$i++;
	}
if ($servername ne $name) { print "WTF names $servername ne $name" ; exit; } ;

print "Cur status: $status\tvlan: $vlan\nWant to continue?\n" ;
my $case = (<STDIN>);
chomp($case);
unless ($case eq "yes") { print "Aborting..\n" ; exit; } ;   

$m->post($urlupdate, Content =>
{ 
	_csrf => $csrf, 
	'DataCenterServer[switch_id]' => $sw_id, 
	'DataCenterServer[name]' => $name, 
	'DataCenterServer[type_id]' => $type_id, 
	'DataCenterServer[status]' => $status, 
	'DataCenterServer[expiration_date]' => $expr, 
	'DataCenterServer[port]' => $port,  
	'DataCenterServer[vlan]' => $vlan, 
	'DataCenterServer[port_speed]' => $p_speed, 
	'DataCenterServer[hardware]' => $hw, 
	'DataCenterServer[comment]' => $comm, 
	'DataCenterServer[ip_ipmi]' => $ip_i, 
	'DataCenterServer[ipmi_password]' => $pass_i  
} ) ;

print "Status: ".$m->status."\n";
