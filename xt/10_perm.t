use Test::PAUSE::Permissions;
 
BEGIN { $ENV{RELEASE_TESTING} = 1; }

all_permissions_ok ("HMBRAND");
