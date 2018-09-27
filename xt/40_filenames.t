eval "use Test::Portability::Files";
 
if ($@) {
    print "1..0 # No file name checks available\n";
    exit 0;
    }

BEGIN { $ENV{RELEASE_TESTING} = 1; }

options (use_file_find => 0, test_amiga_length => 1, test_mac_length => 1);
run_tests ();
