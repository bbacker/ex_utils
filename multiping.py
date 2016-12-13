#!/usr/bin/env python2

import argparse
import re
import pyping
import sys
import urllib2
import socket
socket.setdefaulttimeout(10) # seconds
import pprint

parser = argparse.ArgumentParser(description='check via various protocols if servers respond')
parser.add_argument('-p','--protocols', help="list of protocols to use", action='append')
parser.add_argument('hosts', help="list of hosts to check", nargs='*')
args = parser.parse_args()

print("protocols=" , args.protocols)
print("hosts=" , args.hosts)


results={}

for host in args.hosts :
    results[host]={}
    for proto in args.protocols :
        if re.match(r'icmp', proto, re.I) :
            r = pyping.ping(host)
	    worked = 'yes' if (r.ret_code == 0) else 'no'

        if re.match(r'http', proto, re.I) :
	    uri = "http://" + host
	    req=urllib2.Request(uri)
	    try:
		resp=urllib2.urlopen(req)
		info=resp.info()
		status = info[status]
		worked = 'yes' if status == 200 else 'no('+status+')'

	    except urllib2.URLError as e:
		worked='no'

	results[host][proto]=worked

for host in args.hosts :
    for proto in args.protocols :
	print (host, "	", proto, " = ", results[host][proto])

pp = pprint.PrettyPrinter(indent=4)

pp.pprint(results)
