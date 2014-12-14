#!/usr/bin/env python3
#
# CGI application that queries DBLP for publications in a given venue and
# year range, and displays authors with Greek names.
#
# Copyright 2013 Diomidis Spinellis
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

import cgi
import cgitb
import json
from queue import Queue
import re
import subprocess
import sys
import threading
import urllib.request


# Set the standard output encoding to UTF-8
sys.stdout.close()
sys.stdout = open(1, 'w', encoding='utf-8')

cgitb.enable()  # for troubleshooting

def conf_authors(venue, start, end):
    """Yield the conference authors for the specified data set."""
    for year in range(start, end):
        # Form DBLP query string
        url = ('http://dblp.org/search/api/?q=ce:year:' +
               str(year) +
               ':*%20ce:venue:' + venue + ':*&h=1000&c=4&f=0&format=json')
        response = urllib.request.urlopen(url)
        text_json = response.readall().decode('utf-8')
        text_json = re.sub(r'\\', r'\\\\', text_json)
        data = json.loads(text_json)

        if not data['result']['hits'].get('hit'):
            print("<b>No results found</b>")
            return

        for hit in data['result']['hits']['hit']:
            if not hit['info'].get('authors'):
                continue
            for author in hit['info']['authors']['author']:
                parts = author.split()
                yield (parts[-1] + ' ' + ' '.join(parts[0:-1]))


def query_form():
    """Display the query form."""
    print("""
      <h2>New query</h2>

      <form method="get" action="greek-scientists.py">
        <div class="input-group">
          <span class="input-group-addon">Venue</span>
          <input type="text" class="form-control" placeholder="e.g. icse"
           style="width:50em"
           name="venue" />
        </div>
        <p> (Use <a href='http://www.dblp.org/search/index.php'>DBLP names</a>, like icse or empirical_software_engineering_ese_ or usenix_annual_technical_conference_general_track) </p>

        <p>
        <div class="row">
        <div class="col-lg-3">
        <div class="input-group">
          <span class="input-group-addon">Start year</span>
          <input type="text" class="form-control" placeholder="e.g. 2000 (inclusive)"
           style="width:12em"
           name="start" />
        </div>
        </div>

        <div class="col-lg-3">
        <div class="input-group">
          <span class="input-group-addon">End year</span>
          <input type="text" class="form-control" placeholder="e.g. 2013 (inclusive)"
           style="width:12em"
           name="end" />
        </div>
        </div>
        </div>
        </p>

        <p>
            <button type="submit" class="btn btn-primary">Run query</button>
        </p>
      </form>
    """)

def head():
    """Print the HTTP/HTML results heading."""
    print("""Content-type: text/html

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Locate Greek scientists</title>
<link href="//netdna.bootstrapcdn.com/bootstrap/3.0.3/css/bootstrap.min.css" rel="stylesheet" />
</head>

<body>

<h1>Locate Greek scientists</h1>
""")


def tail():
    """End the results"""
    print ("""
</body>

</html>
""")


def full_writer(output, venue, start, end, writer_q):
    """Write all the names to the classifier."""
    count = 0
    for author in conf_authors(venue, start, end):
        output.write((author + '\n').encode('UTF-8'))
        count = count + 1
    output.close()
    writer_q.put(count)


def greek_reader(input, reader_q):
    """Add names returned by the classifier to the greek_authors set."""
    greek_authors = set()
    for line in input:
        greek_authors.add(line.decode('utf-8'))
    reader_q.put(greek_authors)


def results():
    """Evaluate and display the query's results."""
    form = cgi.FieldStorage()
    venue = form.getvalue("venue")

    try:
        start = int(form.getvalue("start"))
        if start < 1970:
            start = 1970
    except:
        start = None

    try:
        end = int(form.getvalue("end")) + 1
        if end > 2020:
            end = 2020
    except:
        end = None

    if not venue or not start or not end:
        return

    print("<h2>Results</h2>")

    # Filter the results through the greek-classifier
    proc = subprocess.Popen(
            ['/usr/local/bin/greek-classifier', '-u'],
            stdout=subprocess.PIPE,
            stdin=subprocess.PIPE)
    # Queues for getting data from the threads
    writer_q = Queue()
    reader_q = Queue()
    w = threading.Thread(target = full_writer,
                     args=(proc.stdin, venue, start, end, writer_q))
    r = threading.Thread(target = greek_reader, args=(proc.stdout, reader_q))
    r.start()
    w.start()
    total_count = writer_q.get()
    greek_authors = reader_q.get()
    print("<p>"
          "List of {} (probably) Greek authors out of a total of {} authors, "
          "who have published in \"{}\" during the period {}&ndash;{}."
          "</p>".format(len(greek_authors), total_count, cgi.escape(venue),
                        cgi.escape(str(start)), cgi.escape(str(end - 1))))
    print("<hr />")
    for l in greek_authors:
        parts = l.split()
        name = ' '.join(parts[1:]) + ' ' + parts[0]
        print(cgi.escape(name) + '<br />')
    print("<hr />")


head()
query_form()
results()
tail()
