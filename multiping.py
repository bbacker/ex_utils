#!/usr/bin/env python2

import argparse
import re
import pyping

parser = argparse.ArgumentParser(description='check via various protocols if servers respond')
parser.add_argument('-p','--protocols', help="list of protocols to use", action='append')
parser.add_argument("-v", "--verbose", action="count",
                    help="increase output verbosity")

parser.add_argument('hosts', help="list of hosts to check", nargs='*')


args = parser.parse_args()

print ("protocols=%s" , args.protocols)

print ("hosts=" , args.hosts)


for host in args.hosts :
    for proto in args.protocols :
        if re.match(r'icmp', proto, re.I) :
            r = pyping.ping(host)

            if r.ret_code == 0:
                print ("%s ping = yes", host)
            else:
                print ("% ping = no", host)

