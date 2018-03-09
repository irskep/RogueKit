#!/Users/steve/.pyenv/versions/3.6.2/bin/python

import csv
import os
import sys

from pyexcel_ods import get_data

for k, v in get_data(sys.argv[1]).items():
    path = "Resources/{}.csv".format(k)
    if k == "default":
        path = "Resources/palettes/{}.csv".format(k)
    with open(path, 'w', newline='') as f:
        writer = csv.writer(f, lineterminator="\n")
        max_cols = 0
        for row in v:
            max_cols = max(max_cols, len(row))
            writer.writerow([str(c).replace("\n", "\\n") for c in row] + [''] * (max_cols - len(row)))
