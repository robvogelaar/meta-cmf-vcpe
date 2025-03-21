#!/usr/bin/env python3

import cgi
import json
import urllib.parse

import sys
import subprocess
import re
import time
from google.protobuf.json_format import MessageToJson
from copy import deepcopy


getparamresult = '?'
cpe_serial = ''
logs = []
logs2 = []

broker = "revs.dev"
broker_port = "41883"
broker_topic = "/usp/controller"
broker_agent = "/usp/agent"
from_id = "self::usp-controller"
to_id = "proto::rx_usp_agent_mqtt_mv2plus_office_physical"

connected = False
connected_serial = ""


# Preparing the Content-Type header
print("Content-type: text/html\n")

def log(m):
    global logs
    logs.append(m)


def log2(m):
    global logs2
    logs2.append(m)


def mqtt_usp_client(broker, port, topic, broker_agent, from_id, to_id, command, quiet=False):
    # Prepare the command to execute the mqtt-usp-client.py script

    if not quiet:
        log(command)

    script_command = ['./mqtt-usp-client.py', broker, broker_port, broker_topic, broker_agent, from_id, to_id, command]

    result = subprocess.run(script_command, capture_output=True, text=True)

    if result.returncode != 0:
        log("Error in usp controller:")
        log(result.stderr)
        return None

    if not quiet:
        log(result.stdout)
        log2(result.stderr)
    return result.stdout


def UspPa(arg1, arg2, quiet=False):

    global broker
    global broker_port
    global broker_topic
    global broker_agent
    global from_id
    global to_id

    output = None
    for attempt in range(1):

        output = mqtt_usp_client(broker, broker_port, broker_topic, broker_agent, from_id, to_id, arg1 + ' ' + arg2, quiet)
        if output:
            json_output = json.loads(output)
            if arg1 == 'get':
                return(json_output['reqPathResults'][0]['resolvedPathResults'])
            elif arg1 == 'set':
                return(json_output)
            elif arg1 == 'operate':
                return(json_output)
            break

        #print('?')
        time.sleep(1)


# Extracting and parsing URL parameters
params = cgi.FieldStorage()


if params.getvalue("broker", ""):
    broker = params.getvalue("broker", "")

if params.getvalue("broker_port", ""):
    broker_port = params.getvalue("broker_port", "")

if params.getvalue("broker_topic", ""):
    broker_topic = params.getvalue("broker_topic", "")

if params.getvalue("to_id", ""):
    to_id = params.getvalue("to_id", "")


ret = UspPa("get", "Device.DeviceInfo.SerialNumber", True)
if ret:
    cpe_serial = ret[0]["resultParams"]["SerialNumber"]
    connected_serial = cpe_serial
    connected = True
else:
    #print("usp controller cannot connect to:" + broker + ':' + broker_port + ':' + to_id)
    connected_serial = ""
    connected = False
    #exit


cmd = params.getvalue("cmd", "")

if cmd == 'getparam':
    parampath = urllib.parse.unquote_plus(params.getvalue("parampath", ""))
    getparamresult = UspPa("get", parampath)[0]["resultParams"]
    cpe_serial = getparamresult

elif cmd == 'setparam':
    parampath = urllib.parse.unquote_plus(params.getvalue("parampath", ""))
    paramvalue = urllib.parse.unquote_plus(params.getvalue("paramvalue", ""))
    #log("set," + parampath + " " + paramvalue)
    ret = UspPa("set", parampath + " " + paramvalue)

elif cmd == 'install':
    name = urllib.parse.unquote_plus(params.getvalue("name", ""))
    location = urllib.parse.unquote_plus(params.getvalue("location", ""))
    version = urllib.parse.unquote_plus(params.getvalue("version", ""))

    repos={}
    repos["local"]="file:///opt/resident-container-images/"
    repos["share"]="file:///share/"
    repos["remote"]="https://raw.githubusercontent.com/robvogelaar/robvogelaar.github.io/main/unlisted/dac-images/"
    repos["server"]="http://192.168.2.120/"

    # build url
    if location in ["local", "remote", "server", "share"]:
        repo = repos[location]
    if name in ["webui", "tictactoe", "opensync", "rbus", "openvpn"]:
        image = name
    if version in ["1.0", "3.1", "4.4", "5.6"]:
        ver = version
    if cpe_serial.startswith('00163E'):
        arch = 'i686'
    else:
        arch = 'arm'

    url = repo + 'dac-image-' + image + '-v' + ver + '-' + arch + '.tar.gz'

    ee = "default"
    ret = UspPa("operate", f"Device.SoftwareModules.InstallDU(ExecutionEnvRef={ee},UUID=sleepy,URL={url})")
    time.sleep(2)


elif cmd == 'uninstall':
    id = urllib.parse.unquote_plus(params.getvalue("id", ""))
    ret = UspPa("operate", f"Device.SoftwareModules.DeploymentUnit.{id}.Uninstall()")
    time.sleep(2)


elif cmd == 'setrequestedstate':
    id = urllib.parse.unquote_plus(params.getvalue("id", ""))
    state = urllib.parse.unquote_plus(params.getvalue("state", ""))
    ret = UspPa("operate", f"Device.SoftwareModules.ExecutionUnit.{id}.SetRequestedState(RequestedState={state})")
    time.sleep(2)


def get_ees():
    ees=[]
    nr_ees = int(UspPa("get", "Device.SoftwareModules.ExecEnvNumberOfEntries")[0]["resultParams"]["ExecEnvNumberOfEntries"])
    for i in range (1, nr_ees + 1):
        ee = {}
        for key in ["Name", "Enable", "Status", "InitialRunLevel", "CurrentRunLevel"]:
            ee[key] = UspPa("get", f"Device.SoftwareModules.ExecEnv.{i}.")[0]["resultParams"][key]
        ees.append(ee)
    return ees


def get_dus():
    dus=[]
    nr_dus = int(UspPa("get", "Device.SoftwareModules.DeploymentUnitNumberOfEntries")[0]["resultParams"]["DeploymentUnitNumberOfEntries"])
    for i in range (1, nr_dus + 1):
        du = {}
        for key in ["URL", "Status", "ExecutionEnvRef", "ExecutionUnitList"]:
            du[key] = UspPa("get", f"Device.SoftwareModules.DeploymentUnit.{i}.")[0]["resultParams"][key]
        dus.append(du)
    return dus


def get_eus():
    eus = []
    nr_eus = int(UspPa("get", "Device.SoftwareModules.ExecutionUnitNumberOfEntries")[0]["resultParams"]["ExecutionUnitNumberOfEntries"])
    for i in range (1, nr_eus + 1):
        eu = {}
        for key in ["Name", "Status"]:
            eu[key] = UspPa("get", f"Device.SoftwareModules.ExecutionUnit.{i}.")[0]["resultParams"][key]
        eus.append(eu)
    return eus


def get_ees_dus_eus():
    # Parsing logic
    ees = []
    dus = []
    eus = []

    #json_data = UspPa("get", "Device.SoftwareModules.")[0]["reqPathResults"]
    json_data = UspPa("get", "Device.SoftwareModules.")

    #print(json_data)

    # Iterate through the resolvedPathResults to categorize each entry
    #for item in json_data['reqPathResults'][0]['resolvedPathResults']:
    for item in json_data:
        path = item['resolvedPath']
        params = item['resultParams']

        pattern = r"\.(\d+)\."
        match = re.search(pattern, path)
        index = match.group(1) if match else None
        if 'ExecEnv' in path:
            ee = {
                "Index": index,
                "Name": params["Name"],
                "Enable": params["Enable"],
                "Status": params["Status"],
                "InitialRunLevel": params["InitialRunLevel"],
                "CurrentRunLevel": params["CurrentRunLevel"],
            }
            ees.append(ee)
        elif 'DeploymentUnit' in path:
            du = {
                "Index": index,
                "URL": params["URL"],
                "Status": params["Status"],
                "ExecutionEnvRef": params["ExecutionEnvRef"],
                "ExecutionUnitList": params["ExecutionUnitList"]
            }
            dus.append(du)
        elif 'ExecutionUnit' in path:
            eu = {
                "Index": index,
                "Name": params["Name"],
                "Status": params["Status"]
            }
            eus.append(eu)

    return ees, dus, eus

#ee_js_array = get_ees()
#du_js_array = get_dus()
#eu_js_array = get_eus()

if connected:
    ee_js_array, du_js_array, eu_js_array = get_ees_dus_eus()
else:
    ee_js_array = []
    du_js_array = []
    eu_js_array = []


# HTML content
html_content = f"""<!DOCTYPE html>
<html>
<head>
    <link rel="icon" href="https://revs.dev:22445/favicon.ico" type="image/x-icon">
    <title>LCM DAC Demonstrator</title>
    <style>
        body {{
            background-color: #1E2A36; /* Dark blue background */
            color: #D0E1F9; /* Light blue text */
            font-family: Arial, sans-serif;
        }}
        table, th, td {{
            border: 1px solid #4A5E70; /* Darker blue borders */
            border-collapse: collapse;
            padding: 5px;
            text-align: left;
        }}
        .rounded-border {{
            border: 1px solid #4A5E70;
            border-radius: 5px; /* Rounded corners for the border */
            padding: 5px;
            margin-bottom: 10px;
        }}
        th {{
            background-color: #3A4755; /* Medium dark blue header */
            color: #A7BDDC; /* Softer light blue text for headers */
        }}
        td {{
            background-color: #2B3743; /* Slightly lighter blue cells */
        }}
        button, select, input {{
            padding: 5px;
            margin: 5px 5px;
            color: #333;
            background-color: #6CACE4;
            border: none;
            border-radius: 10px;
            cursor: pointer;
        }}
        button {{
            text-transform: uppercase;
            font-weight: bold;
        }}
        select {{
            margin: 1px 5px;
        }}
        input {{
            width: 300px;
        }}
        .form-container {{
            display: flex;
            flex-direction: row; /* Align items in a row */
            align-items: center; /* Center items vertically */
        }}


        .scrollable-text {{
            font-size: 12px;
            color: #999;

            height: 150px; /* Fixed height */
            overflow-y: auto; /* Only show scrollbar if needed */
            border: 1px solid #666; /* Optional: adds a border around the div */
            padding: 5px; /* Optional: adds some padding inside the div */
        }}

        .scrollable-text2 {{
            font-size: 12px;
            color: #999;

            height: 200px; /* Fixed height */
            overflow-y: auto; /* Only show scrollbar if needed */
            border: 1px solid #666; /* Optional: adds a border around the div */
            padding: 5px; /* Optional: adds some padding inside the div */
        }}


    </style>
</head>
<body>

    <div class="rounded-border">
        <div class="form-container">
            <div contenteditable="false" id="broker" style="border: 1px solid #ccc; min-height: 20px; padding: 5px;">
            </div>
            <div contenteditable="false" id="broker_port" style="border: 1px solid #ccc; min-height: 20px; padding: 5px;">
            </div>
            <div contenteditable="false" id="broker_topic" style="border: 1px solid #ccc; min-height: 20px; padding: 5px;">
            </div>
            <div contenteditable="false" id="broker_agent" style="border: 1px solid #ccc; min-height: 20px; padding: 5px;">
            </div>
            <div contenteditable="false" id="from_id" style="border: 1px solid #ccc; min-height: 20px; padding: 5px;">
            </div>
            <select id="to_id" onchange="handleToIdChange()">
                <option value="proto::rx_usp_agent_mqtt_mv2plus_remote_virtual">proto::rx_usp_agent_mqtt_mv2plus_remote_virtual</option>
                <option value="proto::rx_usp_agent_mqtt_mv2plus_office_physical">proto::rx_usp_agent_mqtt_mv2plus_office_physical</option>
                <option value="proto::rx_usp_agent_mqtt_mv2plus_local_physical">proto::rx_usp_agent_mqtt_mv2plus_local_physical</option>
            </select>
            <div contenteditable="false" id="connected_serial" style="border: 1px solid #ccc; min-height: 20px; padding: 5px;">
            </div>
            <button type="button" id="refreshButton">refresh</button>
            <button type="button" id="restartButton">restart</button>
            <button type="button" id="reconnectButton">reconnect</button>
        </div>
    </div>

    <div class="rounded-border">
        <div class="form-container">
            <button type="button" id="getparameterButton">GetParameter</button>
            <select id="getparameterPath">
                <option value="">Parameter:</option>
                <option value="Device.DeviceInfo.SerialNumber">Device.DeviceInfo.SerialNumber</option>
                <option value="Device.X_LGI-COM_General_Internal.CurrentLanguage">Device.X_LGI-COM_General_Internal.CurrentLanguage</option>
            </select>
            <input type="text" id="displayVariable" value="{getparamresult}" readonly>
        </div>

        <div class="form-container">
            <button type="button" id="setparameterButton">SetParameter</button>
            <select id="setparameterPath">
                <option value="">Parameter:</option>
                <option value="Device.X_LGI-COM_General_Internal.CurrentLanguage">Device.X_LGI-COM_General_Internal.CurrentLanguage</option>
                <option value="Device.Users.User.3.X_CISCO_COM_Password">Device.Users.User.3.X_CISCO_COM_Password</option>
            </select>
            <input type="text" id="setparameterValue" placeholder="Value...">
        </div>
    </div>

    <div class="rounded-border">
        <i>Execution Environments (EE)</i>
        <table id="tableEE"></table>
    </div>

    <div class="rounded-border">
        <i>Deployment Units (DU)</i>
        <table id="tableDU"></table>
        <div class="form-container">
            <button type="button" id="installButton">Install()</button>
            <select id="installName">
                <option value="">Name:</option>
                <option value="webui">Web UI</option>
                <option value="tictactoe">Tic Tac Toe</option>
                <option value="opensync">Open Sync</option>
                <option value="rbus">RBus</option>
                <option value="openvpn">Open VPN</option>
            </select>
            <select id="installLocation">
                <option value="">Location:</option>
                <option value="local">Local</option>
                <option value="remote">Remote</option>
                <option value="server">Server</option>
                <option value="share">Share</option>
            </select>
            <select id="installVersion">
                <option value="">Version:</option>
                <option value="1.0">1.0</option>
                <option value="2.0">2.0</option>
                <option value="3.1">3.1</option>
                <option value="4.4">4.4</option>
                <option value="5.6">5.6</option>
            </select>
        </div>
        <div class="form-container">
            <button type="button" id="uninstallButton">Uninstall()</button>
            <select id="uninstallName">
                <option value="">Name:</option>
            </select>
        </div>
    </div>

    <div class="rounded-border">
        <i>Execution Units (EU)</i>
        <table id="tableEU"></table>
        <div class="form-container">
            <button type="button" id="setrequestedstateButton">SetRequestedState()</button>
            <select id="setrequestedstateName">
                <option value="">Id:</option>
            </select>
            <select id="setrequestedstateState">
                <option value="">State:</option>
                <option value="Active">Active</option>
                <option value="Idle">Idle</option>
            </select>
        </div>
    </div>

    <div class="scrollable-text"></div>
    <div class="scrollable-text2"></div>


    <script>
        const EE = {ee_js_array};
        const DU = {du_js_array};
        const EU = {eu_js_array};
        to_id = "{to_id}";


        function handleToIdChange() {{
            to_id = document.getElementById('to_id').value;
            window.location.href = `?to_id=${{encodeURIComponent(to_id)}}`;
        }}

        function populateTable(tableId, dataArray) {{
          const table = document.getElementById(tableId);
          // Check if dataArray is empty
          if (!dataArray.length) return;

          // Create a header row
          const header = table.createTHead().insertRow(0);

          // Insert a header cell for the index column
          let headerCell = document.createElement("th");
          headerCell.textContent = "#"; // Label for the index column
          header.appendChild(headerCell);

          // Insert header cells for each key in the dataArray objects
          Object.keys(dataArray[0]).forEach(key => {{
            headerCell = document.createElement("th");
            headerCell.textContent = key.toUpperCase(); // Use the key names as labels and make them uppercase
            header.appendChild(headerCell);
          }});

          // Populate the table with data
          dataArray.forEach((item, index) => {{
            const row = table.insertRow(-1); // Insert a row at the end of the table
            let cell = row.insertCell(0);
            cell.textContent = index + 1; // Index column
            Object.keys(item).forEach((key, idx) => {{
              cell = row.insertCell(idx + 1);
              cell.textContent = item[key];
            }});
          }});
        }}

        function populateSelect(selectId, dataArray, propName = 'URL') {{
            const select = document.getElementById(selectId);
            dataArray.forEach((item) => {{
                const option = document.createElement("option");
                option.value = item[propName]; // Dynamically assign property for different selects
                option.textContent = item[propName]; // Use propName to differentiate between URL, location, version
                select.appendChild(option);
            }});
        }}


        function addTextToScrollableArea(lines, target) {{
            const scrollableDiv = document.querySelector(target);
            if (scrollableDiv) {{
                lines.forEach(line => {{
                if (line.trim() !== '') {{ // Check if the line is not just whitespace
                    const newParagraph = document.createElement('p');
                    newParagraph.textContent = line;
                    scrollableDiv.appendChild(newParagraph);
                }} else {{
                    // If the line is empty, add a line break for spacing
                    scrollableDiv.appendChild(document.createElement('br'));
                }}
            }});

            // Scroll to the bottom
            scrollableDiv.scrollTop = scrollableDiv.scrollHeight;
            }}
        }}

        function brokerIPInput() {{
            globalText = document.getElementById("broker").innerText;
            console.log("Global Text Updated: ", globalText);
        }}


        addTextToScrollableArea({logs}, '.scrollable-text');
        addTextToScrollableArea({logs2}, '.scrollable-text2');


        // Populate tables and selects
        populateTable("tableEE", EE);
        populateTable("tableDU", DU);
        populateTable("tableEU", EU);
        populateSelect("uninstallName", DU, 'URL');
        populateSelect("setrequestedstateName", EU, 'Name');

        // Populate broker details
        document.getElementById("broker").innerText = "{broker}";
        document.getElementById("broker_port").innerText = "{broker_port}";
        document.getElementById("broker_topic").innerText = "{broker_topic}";
        document.getElementById("broker_agent").innerText = "{broker_agent}";
        document.getElementById("from_id").innerText = "{from_id}";
        document.getElementById("to_id").value = "{to_id}";


        connected_serial = "{connected_serial}";
        if (connected_serial == "") {{
            document.getElementById("connected_serial").innerText = "not connected!";
            document.getElementById("connected_serial").style.color = "red";
            document.getElementById("connected_serial").style.border = "2px solid red";
        }} else {{
            document.getElementById("connected_serial").innerText = connected_serial;
            document.getElementById("connected_serial").style.color = "green";
            document.getElementById("connected_serial").style.border = "2px solid green";
        }}


        document.getElementById("broker").addEventListener("input", brokerIPInput);

        // Event listeners for buttons
        document.getElementById('refreshButton').addEventListener('click', function() {{
            window.location.href = `?cmd=refresh&to_id=${{encodeURIComponent(to_id)}}`;
        }});

        document.getElementById('restartButton').addEventListener('click', function() {{
            window.location.href = `?cmd=restart&to_id=${{encodeURIComponent(to_id)}}`;
        }});

        document.getElementById('reconnectButton').addEventListener('click', function() {{
            window.location.href = `?cmd=reconnect&to_id=${{encodeURIComponent(to_id)}}`;
        }});


        document.getElementById('getparameterButton').addEventListener('click', function() {{
            const getparameterPath = document.getElementById('getparameterPath').value;
            if(getparameterPath) {{
                //to_id = document.getElementById('to_id').value;
                window.location.href = `?cmd=getparam&parampath=${{encodeURIComponent(getparameterPath)}}&to_id=${{encodeURIComponent(to_id)}}`;
            }} else {{
                alert("Please select a Parameter.");
            }}
        }});

        document.getElementById('setparameterButton').addEventListener('click', function() {{
            const setparameterPath = document.getElementById('setparameterPath').value;
            const setparameterValue = document.getElementById('setparameterValue').value;
            if(setparameterPath && setparameterValue) {{
                window.location.href = `?cmd=setparam&parampath=${{encodeURIComponent(setparameterPath)}}&paramvalue=${{encodeURIComponent(setparameterValue)}}&to_id=${{encodeURIComponent(to_id)}}`;
            }} else {{
                alert("Please select a Parameter / Value.");
            }}
        }});

        document.getElementById('installButton').addEventListener('click', function() {{
            const installName = document.getElementById('installName').value;
            const installLocation = document.getElementById('installLocation').value;
            const installVersion = document.getElementById('installVersion').value;
            if(installName && installLocation && installVersion) {{
                window.location.href = `?cmd=install&name=${{encodeURIComponent(installName)}}&location=${{encodeURIComponent(installLocation)}}&version=${{encodeURIComponent(installVersion)}}&to_id=${{encodeURIComponent(to_id)}}`;
            }} else {{
                alert("Please select a deployment unit / location / version to install.");
            }}
        }});

        document.getElementById('uninstallButton').addEventListener('click', function() {{
            const uninstallName = document.getElementById('uninstallName').value;
            if(uninstallName) {{
                index = -1
                for (let i = 0; i < DU.length; i++) {{
                    if (DU[i]['URL'] === uninstallName) {{
                        index = DU[i]['Index']
                        break;
                    }}
                }}

                window.location.href = `?cmd=uninstall&id=${{encodeURIComponent(index)}}&to_id=${{encodeURIComponent(to_id)}}`;
            }} else {{
                alert("Please select a deployment unit to uninstall.");
            }}
        }});


        document.getElementById('setrequestedstateButton').addEventListener('click', function() {{
            const setrequestedstateName = document.getElementById('setrequestedstateName').value;
            const setrequestedstateState = document.getElementById('setrequestedstateState').value;
            if(setrequestedstateName) {{
                index = -1
                for (let i = 0; i < EU.length; i++) {{
                    if (EU[i]['Name'] === setrequestedstateName) {{
                        index = EU[i]['Index']
                        break;
                    }}
                }}

                window.location.href = `?cmd=setrequestedstate&id=${{encodeURIComponent(index)}}&state=${{encodeURIComponent(setrequestedstateState)}}&to_id=${{encodeURIComponent(to_id)}}`;
            }} else {{
                alert("Please select a Id and State.");
            }}
        }});


    </script>
</body>
</html>"""

print(html_content)
