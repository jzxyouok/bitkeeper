#!/usr/bin/perl -w
# Copyright 2012-2013,2015-2016 BitMover, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


my %lines;
my %defset;

$tmp = "cfgtest$$.c";
open(T, ">$tmp");

open(S, "local_string.h");

# don't include str.cfg
print T "#define MK_STR_CFG\n";

# and enable all functions
while (<S>) {
    if (/ifdef\s+(\w+)/) {
	print T "#define $1\n";
	$defset{$1} = 1;
	$lines{$. + 1} = "$1";
    }
}
close(S);

print T "#include \"local_string.h\"\n";
close(T);
open(GCC, "gcc -I.. -Wredundant-decls $tmp 2>&1 |") || die;

# now look for all warnings
while (<GCC>) {
    if (/local_string.h:(\d+)/ and defined($lines{$1})) {
	delete $defset{$lines{$1}};
    }
}
close(GCC);

open(C, ">$tmp");
print C "// autogenerated file\n";
print C "// this enables all string functions not in the C library\n";
foreach (sort keys %defset) {
    print C "#define $_\n";
    print "#define $_\n";
}
close(C);

rename $tmp, "str.cfg";
