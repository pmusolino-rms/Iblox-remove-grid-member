#!/usr/bin/perl
# Finds Grid member in IPAM/DHCP Reservations and removes it
use Infoblox;

my $fh = "grid_remove.out";
open STDOUT, '| tee -ai grid_remove.out';
$GRID_MEMBER = "grid-member-name";
$GRID_IP = "1.2.3.4";

my $session = Infoblox::Session->new(
	master => "1.1.1.1",
	username => "username",
	password => "password" 
	);

if ($session->status_code() ) {
	close(STDOUT);
	die("Construct session failed: ", 
		session0>status_code() . ":" . $session->status_detail());
}
print "Session created successfully\n\n";

print "Retreiving IPAM/DHCP records...\n\n";
my $member = Infoblox::DHCP::Member->new(
     name => $GRID_MEMBER,
     ipv4addr => $GRID_IP,
 );
 my @result_array = $session->search(
     object => "Infoblox::DHCP::Network",
     member => $member,
     #network => "1.2.3.4/24"
 );

unless (@result_array) {
	print ("No IPAM/DHCP records found\n");
}
else {
	print "Finished retreiving records\n\n";

    foreach my $network (@result_array) {

	    print "Network: ";
        print $network->network();
        print "\n";
        $members = $network->members();
        my $new_members = [];
        $has_range = 0;
        foreach my $member (@$members) {
            print $member->name();
            print ":";
            print $member->ipv4addr();
            print "\n";
            if ($member->name() ne $GRID_MEMBER) {
                push @$new_members, $member;
            }
            else {
         	    print "Removing\n";
            }
        }
        my @ranges = $session->search(
	        object  => "Infoblox::DHCP::Range",
	        network => $network->network(),
	        member  => $member,
	    );

	    if (!@ranges) {
		    print "No DHCP Ranges found";
	    }
	    else {
		    $has_range = 1;
		    foreach my $range (@ranges) {
		 	    print $range->name . " Found \n";
		 	    $range->server_association_type("NONE");
		 	    $session->modify($range)
       		        or die("Modify Range attribute failed: ",
            		    $session->status_code() . ":" . $session->status_detail());
		    }
	    }
        print "\nNew members\n";
        foreach my $member (@$new_members) {
            print $member->name();
            print ":";
            print $member->ipv4addr();
            print "\n";
        }
        $network->members($new_members);
        #if ($has_range) {
        #	print "Skipping for now\n";
        #	next;
        #}
        #else {
        #	 $session->modify($network)
        #        or die("Modify Network attribute failed: ",
        #           $session->status_code() . ":" . $session->status_detail());

        #	print "Network object modified successfully \n";
        #}
        $session->modify($network)
      	    or die("Modify Network attribute failed: ",
           	    $session->status_code() . ":" . $session->status_detail());

        print "Network object modified successfully \n";
    }
}

print "Retreiving DNS records...\n\n";

my @result_array = $session->search(
     object => "Infoblox::DNS::Zone",
     #name   => "example\\.com"
 );
unless (@result_array) {
	print("\nNo DNS Zone record found: ",
	    $session->status_code() . ":" . $session->status_detail());
	print "\n";
}
else {

    print "Finished retreiving DNS Zones\n\n";
    foreach my $zone (@result_array) {
    	my $update_flag = 0;
		my $has_member = 0;
		my $has_primary = 0;
		my $has_secondary = 0;
		my $has_stub = 0;
    	print $zone->name;
    	print "\n";

    	my $new_members = [];
	    my $members = $zone->members();
		if (scalar(@$members) > 0) { print "Examining Members...\n";}
        foreach my $member (@$members) {
            print $member->name();
            print ":";
            print $member->ipv4addr();
            print "\n";
            if ($member->name() ne $GRID_MEMBER) {
                push @$new_members, $member;
            }
            else {
            	$has_member = 1;
         	    print "Removing\n";
            }
        }
        my $new_primaryns = [];
        my $primaries = $zone->multiple_primaries();
        if (scalar (@$primaries) > 0) { print "Examining Primaries...\n";}
        foreach my $primary (@$primaries) {
        	print $primary->name();
        	print ":";
            print $primary->ipv4addr();
            print "\n";
            if ($primary->name() ne $GRID_MEMBER) {
                push @$new_primaryns, $primary;
            }
            else {
            	$has_primary = 1;
         	    print "Removing\n";
            }
        }
        my $new_secondaryns = [];
        my $secondaries = $zone->secondaries();
        if (scalar(@$secondaries) > 0) { print "Examining Secondaries...\n";}
        foreach my $secondary (@$secondaries) {
        	print $secondary->name();
        	print ":";
            print $secondary->ipv4addr();
            print "\n";
            if ($secondary->name() ne $GRID_MEMBER) {
                push @$new_secondaryns, $secondary;
            }
            else {
            	$has_secondary = 1;
         	    print "Removing\n";
            }
        }
        my $new_stubns = [];
        my $stub_members = $zone->stub_members();
        if (scalar(@$stub_members) > 0) { print "Examining Stubs...\n";}
        foreach my $stub_member (@$stub_members) {
        	print $stub_member->name();
        	print ":";
            print $stub_member->ipv4addr();
            print "\n";
            if ($stub_member->name() ne $GRID_MEMBER) {
                push @$new_stubns, $stub_member;
            }
            else {
            	$has_stub = 1;
         	    print "Removing\n";
            }
        }
        if ($has_member == 1) {
	        print "\nNew members\n";
	        foreach my $member (@$new_members) {
	            print $member->name();
	            print ":";
	            print $member->ipv4addr();
	            print "\n";
	        }
	        $zone->members($new_members);
	        $update_flag = 1;
	    }
	    else {
	    	;
	    	#print "Members unchanged\n";
	    }
	    if ($has_primary == 1) {
	        print "\nNew primaries\n";
	        foreach my $primary (@$new_primaryns) {
	            print $primary->name();
	            print ":";
	            print $primary->ipv4addr();
	            print "\n";
	        }
	        $zone->multiple_primaries($new_primaryns);
            $update_flag = 1;
	    }
	    else {
	    	;
	    	#print "Primaries Unchanged\n";
	    }
        if ($has_secondary == 1) {
	        print "\nNew secondaries\n";
	        foreach my $secondary (@$new_secondaryns) {
	            print $secondary->name();
	            print ":";
	            print $secondary->ipv4addr();
	            print "\n";
	        }
	        $zone->secondaries($new_secondaryns);
            $update_flag = 1;
	    }
	    else {
	    	;
	    	#print "Secondaries Unchanged\n";
	    }
	    if ($has_stub == 1) {
	        print "\nNew stub members\n";
	        foreach my $stub_member (@$new_stubns) {
	            print $stub_member->name();
	            print ":";
	            print $stub_member->ipv4addr();
	            print "\n";
	        }
	        $zone->stub_members($new_stubns);
            $update_flag = 1;
	    }
	    else {
	    	;
	    	#print "Stub unchanged\n";
	    }

        if ($update_flag == 1) {
        	print "Zone:" . $zone->name . " updated\n\n";
            $session->modify($zone)
      	        or die("Modify Zone attribute failed: ",
           	        $session->status_code() . ":" . $session->status_detail());
        }
        else {
        	print "No updates to be made\n\n";
        }
    }
}
print "Logging out of session\n\n";
$session->logout();
close(STDOUT);
exit(0);
