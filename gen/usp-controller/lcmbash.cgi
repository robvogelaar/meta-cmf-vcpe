#!/bin/bash


# Extract the QUERY_STRING environment variable
queryString="$QUERY_STRING"

# URL decode function
urldecode() {
  # Using sed to replace %xx with the corresponding character
  echo -e "$(sed 's/+/ /g;s/%\(..\)/\\x\1/g;' <<<"$1")"
}

# Function to parse a parameter from the query string
parse_param() {
  echo "$queryString" | sed -n "s/.*$1=\([^&]*\).*/\1/p" | tr '+' ' '
}

# Parsing parameters "cmd" and "name"
cmd=$(parse_param "cmd")
name=$(parse_param "name")

# URL-decode the name parameter
decodedName=$(urldecode "$name")



# Dynamically generated JavaScript arrays (example data)
EE_JS_ARRAY=$(cat <<'EOF'
[
    {"Name": "default", "Enable": "True", "Status": "Up", "InitialRunLevel": "5", "CurrentRunLevel": "5"},
    {"Name": "test", "Enable": "True", "Status": "Up", "InitialRunLevel": "5", "CurrentRunLevel": "5"},
    {"Name": "user", "Enable": "True", "Status": "Up", "InitialRunLevel": "5", "CurrentRunLevel": "5"}
]
EOF
)

DU_JS_ARRAY=$(cat <<'EOF'
[
    {"URL": "file:///op...age-tictactoe-v1.0-i686.tar.gz", "Status": "Installed", "ExecutionEnvRef": "Device.SoftwareModules.ExecEnv.1", "ExecutionUnitList": "Device.SoftwareModules.ExecutionUnit.1"},
    {"URL": "file:///op...ac-image-rbus-v1.0-i686.tar.gz", "Status": "Installed", "ExecutionEnvRef": "Device.SoftwareModules.ExecEnv.2", "ExecutionUnitList": "Device.SoftwareModules.ExecutionUnit.2"}
]
EOF
)

EU_JS_ARRAY=$(cat <<'EOF'
[
    {"Name": "Kn", "Status": "Active"},
    {"Name": "NX", "Status": "Active"}
]
EOF
)

# Send the HTTP header
echo "Content-type: text/html"
echo "" # an empty line is necessary after the header

# Output the HTML document with the dynamically generated JavaScript variables
cat <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>System Information</title>
    <style>
        body {
            background-color: #1E2A36; /* Dark blue background */
            color: #D0E1F9; /* Light blue text */
            font-family: Arial, sans-serif;
        }
        table, th, td {
            border: 1px solid #4A5E70; /* Darker blue borders */
            border-collapse: collapse;
            padding: 5px;
            text-align: left;
        }
        .rounded-border {
            border: 2px solid #4A5E70;
            border-radius: 15px; /* Rounded corners for the border */
            padding: 10px;
            margin-bottom: 20px;
        }
        th {
            background-color: #3A4755; /* Medium dark blue header */
            color: #A7BDDC; /* Softer light blue text for headers */
        }
        td {
            background-color: #2B3743; /* Slightly lighter blue cells */
        }
        button {
            padding: 10px 20px;
            font-size: 1em; /* Adjusted to match the SetRequestedState text size */
            margin: 10px 5px;
            color: #333;
            background-color: #6CACE4;
            border: none;
            cursor: pointer;
            border-radius: 4px;
            min-width: 150px; /* Adjusted to fit the text "SetRequestedState" */
        }
        select {
            margin: 5px 5px;
            color: #333;
            background-color: #6CACE4;
            border: none;
            padding: 5px;
            border-radius: 4px;
        }
        .form-container {
            display: flex;
            flex-direction: column; /* Changed to column to stack elements vertically */
            align-items: flex-start; /* Align items to the start of the flex container */
        }
        .button-picker-group {
            display: flex;
            flex-direction: row;
            align-items: center;
            flex-wrap: wrap;
        }
    </style>
</head>
<body>
    <div class="rounded-border">
        <h2>Execution Environments (EE)</h2>
        <table id="tableEE">
            <tr>
                <th>#</th>
                <th>Name</th>
                <th>Enable</th>
                <th>Status</th>
                <th>InitialRunLevel</th>
                <th>CurrentRunLevel</th>
            </tr>
        </table>
    </div>

    <div class="rounded-border">
        <h2>Deployment Units (DU)</h2>
        <table id="tableDU">
            <tr>
                <th>#</th>
                <th>URL</th>
                <th>Status</th>
                <th>ExecutionEnvRef</th>
                <th>ExecutionUnitList</th>
            </tr>
        </table>
        <div class="form-container">
            <div class="button-picker-group">
                <button type="button" id="installButton">Install</button>
                <select id="installName">
                    <option value="">Select Name</option>
                    <!-- Dynamically filled from DU 'URL' -->
                </select>
                <select id="location">
                    <option value="">Select Location</option>
                    <option value="local">Local</option>
                    <option value="remote">Remote</option>
                </select>
                <select id="version">
                    <option value="">Select Version</option>
                    <option value="local">Local</option>
                    <option value="remote">Remote</option>
                </select>
            </div>
            <div class="button-picker-group">
                <button type="button">Uninstall</button>
                <select id="uninstallName">
                    <option value="">Select Name</option>
                    <!-- Dynamically filled -->
                </select>
            </div>
        </div>
    </div>

    <div class="rounded-border">
        <h2>Execution Units (EU)</h2>
        <table id="tableEU">
            <tr>
                <th>#</th>
                <th>Name</th>
                <th>Status</th>
            </tr>
        </table>
        <div class="form-container">
            <div class="button-picker-group">
                <button type="button">SetRequestedState</button>
                <select id="setStateName">
                    <option value="">Select Name</option>
                    <!-- Dynamically filled from EU 'Name' -->
                </select>
                <select id="state">
                    <option value="">Select State</option>
                    <option value="active">Active</option>
                    <option value="idle">Idle</option>
                </select>
            </div>
        </div>
    </div>

    <script>
        const EE = $EE_JS_ARRAY;
        const DU = $DU_JS_ARRAY;
        const EU = $EU_JS_ARRAY;

        function populateTable(tableId, data) {
            const table = document.getElementById(tableId);
            data.forEach((item, index) => {
                const row = table.insertRow(-1);
                const rowNumCell = row.insertCell(0);
                rowNumCell.textContent = index + 1;
                Object.values(item).forEach(text => {
                    const cell = row.insertCell(-1);
                    cell.textContent = text;
                });
            });
        }

        function populateSelect(selectId, data, dataField, placeholder = '') {
            const select = document.getElementById(selectId);
            if (placeholder) {
                const placeholderOption = document.createElement('option');
                placeholderOption.textContent = placeholder;
                placeholderOption.value = '';
                select.appendChild(placeholderOption);
            }
            data.forEach((item) => {
                const option = document.createElement('option');
                option.value = option.textContent = item[dataField];
                select.appendChild(option);
            });
        }

        // Populate the tables
        populateTable("tableEE", EE);
        populateTable("tableDU", DU);
        populateTable("tableEU", EU);

        // Dynamically populate 'Name' pickers
        populateSelect("installName", DU, 'URL', 'Select Name'); // From DU 'URL'
        populateSelect("setStateName", EU, 'Name', 'Select Name'); // From EU 'Name'


        // Handle the Install button click

        document.getElementById('installButton').addEventListener('click', function() {
            const installName = document.getElementById('installName').value;

            console.log('Selected install name:', installName);

            if(installName) {
                // Append &cmd=install and the selected name to the URL or handle as needed

                const cmdUrl = window.location.href + "?cmd=install&name=" + encodeURIComponent(installName);
                // const cmdUrl = \"\${window.location.href}?cmd=install\"
                console.log('Constructed cmdUrl:', cmdUrl);

                console.log('Install command URL:', cmdUrl);
                // Example action, such as redirecting or making an AJAX call
                window.location.href = cmdUrl;
            } else {
                alert("Please select a name to install.");
            }
        });

    </script>
</body>
</html>
EOF

