#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

#$ENV{TEST_VERBOSE} = 1;

use Modern::Perl;

use Test::More tests => 3;

use Cwd;
use IPC::Cmd;
use File::Slurp;
use File::Temp;

use Test::Harness::KS;

my $testResultsDir = File::Temp::tempdir( CLEANUP => 1 );
my $p = {};
Test::Harness::KS::getTestResultFileAndDirectoryPaths($p, $testResultsDir); #Find out the paths where all the test deliverables are brought to.

subtest "Execute example script", sub {
  plan tests => 1;
  my $cmd = "/usr/bin/env perl bin/test-harness-ks --clover --tar --all --junit --results-dir $testResultsDir";
  my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
          IPC::Cmd::run( command => $cmd, verbose => 0 );
  if ($ENV{TEST_VERBOSE}) {
    print "CMD: $cmd\nERROR MESSAGE: $error_message\nSTDOUT:\n@$stdout_buf\nSTDERR:\n@$stderr_buf\nCWD:".Cwd::getcwd();
  }


  ok($success, "Example script executed successfully");
  unless ($success) {
    BAIL_OUT("Example script execution failed, so no point in verifying test results\nProgram output:\nERROR MESSAGE: $error_message\nSTDOUT:\n@$stdout_buf\nSTDERR:\n@$stderr_buf\nCWD:".Cwd::getcwd());
  }
};


subtest "Clover tests", sub {
  plan tests => 4;
  ok(-e $p->{cloverDir},
     "Clover dir created");

  ok(-e $p->{cloverDir}.'/clover.xml',
     "Clover report created");

  ok(my $contents = File::Slurp::read_file($p->{cloverDir}.'/clover.xml'),
     "Clover report slurped");

  like($contents, qr/<coverage generated="\d+" clover="\d+\.\d+"/,
     "Looks like a Clover xml-file");
};


subtest "Junit tests", sub {
  plan tests => 6;
  ok(-e 't/testResults/junit',
     "Junit dir created");

  ok(-e $p->{junitDir}.'/t.t.xml',
     "Junit unit test result created");

  ok(-e $p->{junitDir}.'/t.t.xt.xml',
     "Junit xt test result created");

  ok(-e $p->{junitDir}.'/t.t.integration.xml',
     "Junit integration test result created");

  ok(my $contents = File::Slurp::read_file($p->{junitDir}.'/t.t.integration.xml'),
     "Junit integration report slurped");

  like($contents, qr/\Q<testsuite name="t.t.integration.03-integration_t"\E/,
     "Looks like a Junit xml-file");
};

done_testing;
