#!/bin/python3

import sys
from datetime import timedelta
import plotly.graph_objs as go
import plotly.io as pio


def read_data(filename):
    data = {}
    with open(filename, 'r') as f:
        time = 0
        prev_free_mem = None
        for line in f:

            #TIME 120

            #   0           1       2    3    4      5     6  7          8     9          10       11      12
            #USER         PID    PPID %CPU %MEM    VSZ   RSS TT       STAT START     ELAPSED     TIME COMMAND
            #root         439       1  0.7  0.1 118712 12432 ?        Ssl  15:06       01:59 00:00:00 /usr/bin/CcspPandMSsp -subsys eRT.

            #              total        used        free      shared  buff/cache   available
            #Mem:        7981872     6684996      151032      287480     1145844      714388
            #Swap:       2097148      862976     1234172

            if line.startswith('TIME'):
                time = int(line.split()[1])

            elif any(line.startswith(s) for s in ['root', 'dnsmasq', 'ntp']):
                if line.split()[12].startswith('ps --sort'):
                    continue
                fields = line.strip().split()
                if int(fields[6]) < 3000:
                    continue
                process = fields[12] + '(' + fields[1] +')'
                mem = float(fields[6])
                if process not in data:
                    data[process] = {'time': [], 'mem': []}
                data[process]['time'].append(time)
                data[process]['mem'].append(mem)

            elif line.startswith('Mem:'):
                fields = line.strip().split()
                process = 'system free (delta)'
                mem = float(fields[3])
                if prev_free_mem is not None:
                    delta = mem - prev_free_mem
                    if process not in data:
                        data[process] = {'time': [], 'mem': []}
                    data[process]['time'].append(time)
                    data[process]['mem'].append(delta)
                prev_free_mem = mem
    return data


def format_time(seconds):
    time_str = str(timedelta(seconds=seconds))
    return time_str[:-3]  # Remove the last three characters (seconds and colon)


# read in the data from the input file
filename = sys.argv[1]  # replace with your input file name
data = read_data(filename)

# create a plot for each process's memory usage over time
fig = go.Figure()

for process, values in data.items():
    formatted_time = [format_time(t) for t in values["time"]]
    is_system_free = process == 'system free (delta)'

    fig.add_trace(
        go.Scatter(
            x=formatted_time,
            y=values["mem"],
            mode="lines+markers",
            name=process,
            text=[process] * len(values["time"]),
            hovertemplate="<b>%{text}</b><br>Time: %{x}<br>Memory: %{y}<extra></extra>",
            yaxis='y2' if is_system_free else 'y1',
        )
    )

# set labels and title
fig.update_layout(
    title="Memory usage over time",
    xaxis_title="Time (HH:MM)",
    yaxis_title="Memory usage (KB)",
    yaxis2=dict(
        title="System free memory (KB)",
        anchor="x",
        overlaying="y",
        side="right",
        range=[-500000, 500000],  # Scale
    ),
    legend=dict(orientation="v", yanchor="top", y=1, xanchor="left", x=1.12),
)

# save the plot to an HTML file
pio.write_html(fig, file=sys.argv[1].split('.')[0] + ".html", auto_open=False)

print(sys.argv[1].split('.')[0] + '.html')
